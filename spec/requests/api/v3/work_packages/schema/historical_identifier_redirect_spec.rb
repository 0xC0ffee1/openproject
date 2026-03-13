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

require "spec_helper"
require "rack/test"

RSpec.describe "API v3 WorkPackage Schema historical identifier redirect", content_type: :json do
  shared_let(:project) { create(:project, :with_types) }
  shared_let(:type) { project.types.first }
  shared_let(:user) do
    create(:user,
           member_with_roles: { project => create(:project_role, permissions: [:view_work_packages]) })
  end

  current_user { user }

  describe "GET /api/v3/work_packages/schemas/:project-:type" do
    it_behaves_like "API redirects GET requests using a historical project identifier with dynamic path" do
      let(:path_with_old_id) { "/api/v3/work_packages/schemas/#{old_identifier}-#{type.id}" }
      let(:current_identifier_pattern) { "#{project.identifier}-#{type.id}" }
    end
  end
end
