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

class InitializeHistoricIdentifiers < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      INSERT INTO friendly_id_slugs (slug, sluggable_id, sluggable_type, scope, created_at)
      SELECT p.identifier, p.id, 'Project', NULL, NOW()
      FROM projects p
      WHERE p.identifier IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM friendly_id_slugs fis
        WHERE fis.slug = p.identifier
        AND fis.sluggable_id = p.id
        AND fis.sluggable_type = 'Project'
        AND fis.scope IS NULL
      )
    SQL
  end

  def down
    # nothing to do / not possible
  end
end
