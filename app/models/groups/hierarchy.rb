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

module Groups::Hierarchy
  extend ActiveSupport::Concern

  # Direct children of this group.
  def children
    Group.where_detail(parent_id: id)
  end

  # All groups below this one in the tree (any depth).
  def descendants
    Group.where(id: descendant_ids)
  end

  # Self and all descendant groups.
  def self_and_descendants
    Group.where(id: [id] + descendant_ids)
  end

  # All groups above this one in the tree up to the root.
  def ancestors
    Group.where(id: ancestor_ids)
  end

  # Self and all ancestor groups, ordered from root down.
  def self_and_ancestors
    Group.where(id: [id] + ancestor_ids)
  end

  # The topmost group in this tree. Returns self if already the root.
  # Note: relies on Postgres UNION ALL CTE processing rows in insertion order,
  # so ancestor_ids are returned child-first; the last entry is the root.
  def root
    root_id = ancestor_ids.last
    root_id ? Group.find(root_id) : self
  end

  # True if this group has no parent.
  def root?
    parent_id.nil?
  end

  private

  def descendant_ids
    return [] if new_record?

    sql = self.class.sanitize_sql([<<~SQL.squish, id])
      WITH RECURSIVE group_descendants(id) AS (
        SELECT gd.principal_id
        FROM group_details gd
        WHERE gd.parent_id = ?

        UNION ALL

        SELECT gd.principal_id
        FROM group_details gd
        INNER JOIN group_descendants ON gd.parent_id = group_descendants.id
      )
      SELECT id FROM group_descendants
    SQL

    self.class.connection.select_values(sql, "Group descendants")
  end

  def ancestor_ids
    return [] if new_record? || parent_id.nil?

    sql = self.class.sanitize_sql([<<~SQL.squish, id])
      WITH RECURSIVE group_ancestors(id) AS (
        SELECT gd.parent_id
        FROM group_details gd
        WHERE gd.principal_id = ? AND gd.parent_id IS NOT NULL

        UNION ALL

        SELECT gd.parent_id
        FROM group_details gd
        INNER JOIN group_ancestors ON gd.principal_id = group_ancestors.id
        WHERE gd.parent_id IS NOT NULL
      )
      SELECT id FROM group_ancestors
    SQL

    self.class.connection.select_values(sql, "Group ancestors")
  end
end
