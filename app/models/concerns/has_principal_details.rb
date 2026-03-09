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

module HasPrincipalDetails
  extend ActiveSupport::Concern

  class_methods do
    # Declares a detail table for this principal subclass.
    #
    # @param class_name [String] the detail model class (default: "#{ModelName}Detail")
    # @param delegated_attributes [Hash] attribute => delegate options
    #
    # Example:
    #   has_principal_details "GroupDetail",
    #     organizational_unit: { allow_nil: true },
    #     parent: { allow_nil: true }
    #
    def has_principal_details(class_name = nil, **delegated_attributes) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Naming/PredicatePrefix
      class_name ||= "#{name}Detail"
      association_name = class_name.underscore.to_sym

      has_one association_name, foreign_key: :principal_id,
                                dependent: :destroy,
                                inverse_of: model_name.element.to_sym,
                                class_name: class_name.to_s,
                                autosave: true
      accepts_nested_attributes_for association_name

      # Validate the detail record and promote its errors onto the principal
      # so they appear as direct attributes (e.g. group.errors[:parent_id]).
      validate do
        next if detail.nil? || detail.valid?

        detail.errors.each do |error|
          errors.add(error.attribute, error.type, message: error.message)
        end
      end

      # Auto-build the detail record so it's never nil
      after_initialize do
        build_detail if new_record? && detail.nil?
      end

      # Convenience aliases so every subclass can use `detail`
      alias_method :detail, association_name
      alias_method :detail=, :"#{association_name}="
      alias_method :build_detail, :"build_#{association_name}"

      detail_class = class_name.constantize

      delegated_attributes.each do |attr, options|
        opts = options.is_a?(Hash) ? options : {}
        delegate attr, to: association_name, **opts
        # Also delegate the writer if it exists (skip for query methods ending in ?)
        delegate "#{attr}=", to: association_name, **opts unless attr.to_s.end_with?("?")

        # For belongs_to associations, also delegate the _id getter and setter
        if detail_class.reflect_on_association(attr)&.macro == :belongs_to
          delegate "#{attr}_id", to: association_name, **opts
          delegate "#{attr}_id=", to: association_name, **opts
        end
      end
    end
  end
end
