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

class RbMasterBacklogsController < RbApplicationController
  include WorkPackages::WithSplitView

  menu_item :backlogs

  before_action :not_authorized_on_feature_flag_inactive, only: :sprint_planning
  before_action :load_backlogs, only: %i[index sprint_planning]

  def sprint_planning
    if turbo_frame_request?
      render partial: "sprint_planning_list", layout: false
    else
      render :sprint_planning
    end
  end

  def index
    if turbo_frame_request?
      render partial: "list", layout: false
    else
      render :index
    end
  end

  def details
    if turbo_frame_request?
      render "work_packages/split_view", layout: false
    else
      load_backlogs

      if OpenProject::FeatureDecisions.scrum_projects_active?
        render :sprint_planning
      else
        render :index
      end
    end
  end

  def split_view_base_route
    if OpenProject::FeatureDecisions.scrum_projects.active?
      sprint_planning_backlogs_project_backlogs_path(@project)
    else
      backlogs_project_backlogs_path(request.query_parameters)
    end
  end

  private

  def load_backlogs
    @owner_backlogs = Backlog.owner_backlogs(@project)

    if OpenProject::FeatureDecisions.scrum_projects_active?
      @sprints = Agile::Sprint.for_project(@project).not_completed.order_by_date
    else
      @sprint_backlogs = Backlog.sprint_backlogs(@project)
    end
  end
end
