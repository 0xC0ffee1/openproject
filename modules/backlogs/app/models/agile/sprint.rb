# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# Intended to eventually replace the `Sprint` model from models/sprint.rb
# Namespaced for now so that the rest of the application can keep using the old model.
# Remove this namespace and the old class once all usages have been replaced.
module Agile
  class Sprint < ApplicationRecord
    self.table_name = "sprints"

    belongs_to :project
    has_many :work_packages, dependent: :nullify

    scope :for_project, ->(project) { where(project:) }
    scope :not_completed, -> { !completed }
    scope :order_by_date, -> do
      order(arel_table[:start_date].asc.nulls_last,
            arel_table[:finish_date].asc.nulls_last)
    end

    enum :status,
         {
           in_planning: "in_planning",
           active: "active",
           completed: "completed"
         },
         default: "in_planning",
         validate: true

    enum :sharing,
         {
           none: "none",
           descendants: "descendants",
           system: "system"
         },
         default: "none",
         prefix: :sharing_with,
         validate: true

    validates :name, presence: true
    validates :project, presence: true
    validates :start_date, presence: true
    validates :finish_date, presence: true
    validates :finish_date,
              comparison: { greater_than_or_equal_to: :start_date },
              if: :start_date?

    validate :validate_only_one_active_sprint_per_project

    include ::Scopes::Scoped

    scopes :visible

    # TODO: validate sharing is set to an allowed value, e.g. only admins may share systemwide (#71374, #71253)
    # TODO: implement sharing logic once it has been defined (#71374)

    def date_range_set?
      start_date? && finish_date?
    end

    def duration
      return nil unless date_range_set?

      Day.working.from_range(from: start_date, to: finish_date).count
    end

    private

    # TODO: consider moving this validation to the database level to ensure data integrity.
    # Doing this in Rails can lead to race conditions. Revisit this topic once the sharing
    # logic has been fully specified.
    def validate_only_one_active_sprint_per_project
      return if !active? || project_id.blank?

      existing_active_sprint = self.class
                                   .where(project_id:, status: "active")
                                   .where.not(id:)
                                   .exists?

      if existing_active_sprint
        errors.add(:status, :only_one_active_sprint_allowed)
      end
    end
  end
end
