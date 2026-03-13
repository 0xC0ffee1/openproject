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

class CreateFriendlyIdSlugs < ActiveRecord::Migration[8.1]
  def change
    create_table :friendly_id_slugs do |t|
      t.string   :slug,           null: false
      t.bigint   :sluggable_id,   null: false
      t.string   :sluggable_type, limit: 50
      t.string   :scope
      t.datetime :created_at
    end

    add_index :friendly_id_slugs, %i[sluggable_type sluggable_id]
    add_index :friendly_id_slugs, %i[slug sluggable_type],
              length: { slug: 140, sluggable_type: 50 }
    add_index :friendly_id_slugs, %i[slug sluggable_type scope],
              length: { slug: 70, sluggable_type: 50, scope: 70 },
              unique: true
  end
end
