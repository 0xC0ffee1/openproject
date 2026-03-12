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

class RbSprintsController < RbApplicationController
  include OpTurbo::ComponentStream

  NEW_SPRINT_ACTIONS = %i[new_dialog
                          edit_dialog
                          create
                          refresh_form
                          update_agile_sprint].freeze

  skip_before_action :load_sprint_and_project, only: NEW_SPRINT_ACTIONS

  before_action :not_authorized_on_feature_flag_inactive,
                :load_project,
                only: NEW_SPRINT_ACTIONS

  def new_dialog
    call = Sprints::SetAttributesService.new(
      user: current_user,
      model: Agile::Sprint.new,
      contract_class: EmptyContract
    ).call(attributes: converted_agile_sprint_params)

    respond_with_dialog Backlogs::NewSprintDialogComponent.new(sprint: call.result)
  end

  def edit_dialog
    @sprint = Agile::Sprint.for_project(@project).visible.find(params[:id])

    respond_with_dialog Backlogs::NewSprintDialogComponent.new(sprint: @sprint, state: :edit)
  end

  def refresh_form
    id = edit_agile_sprint_params.dig(:sprint, :id)
    sprint = id.present? ? Agile::Sprint.for_project(@project).visible.find(id) : Agile::Sprint.new

    call = Sprints::SetAttributesService.new(
      user: current_user,
      model: sprint,
      contract_class: EmptyContract
    ).call(attributes: converted_agile_sprint_params)

    update_via_turbo_stream(component: Backlogs::NewSprintFormComponent.new(sprint: call.result))

    respond_with_turbo_streams
  end

  def create # rubocop:disable Metrics/AbcSize
    call = Sprints::CreateService
             .new(user: current_user)
             .call(attributes: converted_agile_sprint_params)

    if call.success?
      flash[:notice] = I18n.t(:notice_successful_create)
      render turbo_stream: turbo_stream.redirect_to(sprint_planning_backlogs_project_backlogs_path(@project))
    else
      update_new_sprint_form_component_via_turbo_stream(sprint: call.result, base_errors: call.errors[:base])
      respond_with_turbo_streams
    end
  end

  # Called like this due to `update` being taken by legacy sprints.
  def update_agile_sprint # rubocop:disable Metrics/AbcSize
    @sprint = Agile::Sprint.for_project(@project).visible.find(params[:id])

    call = Sprints::UpdateService
             .new(user: current_user, model: @sprint)
             .call(attributes: agile_sprint_params[:sprint])

    if call.success?
      render_success_flash_message_via_turbo_stream(message: I18n.t(:notice_successful_update))
      update_sprint_header_component_via_turbo_stream(sprint: call.result)
    else
      update_new_sprint_form_component_via_turbo_stream(sprint: call.result, base_errors: call.errors[:base])
    end

    respond_with_turbo_streams
  end

  def edit_name
    update_header_component_via_turbo_stream(state: :edit)
    respond_with_turbo_streams
  end

  def show_name
    update_header_component_via_turbo_stream(state: :show)
    respond_with_turbo_streams
  end

  def update
    call = Versions::UpdateService
      .new(user: current_user, model: @sprint)
      .call(attributes: sprint_params)

    if call.success?
      status = 200
      state = :show
      @sprint = call.result
      render_success_flash_message_via_turbo_stream(message: I18n.t(:notice_successful_update))
    else
      status = 422
      state = :edit
      render_error_flash_message_via_turbo_stream(
        message: I18n.t(:notice_unsuccessful_update_with_reason, reason: call.message)
      )
    end

    update_header_component_via_turbo_stream(state:)
    respond_with_turbo_streams(status:)
  end

  private

  def update_header_component_via_turbo_stream(state: :show)
    @backlog = Backlog.for(sprint: @sprint, project: @project)

    update_via_turbo_stream(
      component: Backlogs::BacklogHeaderComponent.new(
        backlog: @backlog,
        project: @project,
        state:
      ),
      method: :morph
    )
  end

  def update_sprint_header_component_via_turbo_stream(sprint:)
    update_via_turbo_stream(
      component: Backlogs::SprintHeaderComponent.new(sprint:),
      method: :morph
    )
  end

  def update_new_sprint_form_component_via_turbo_stream(sprint:, base_errors: nil)
    update_via_turbo_stream(
      component: Backlogs::NewSprintFormComponent.new(
        sprint:,
        base_errors:
      ),
      status: :bad_request
    )
  end

  # Overrides load_sprint_and_project to load the sprint from :id instead of :sprint_id
  def load_sprint_and_project
    @sprint = Sprint.visible.find(params[:id])
    load_project
  end

  def sprint_params
    params.expect(sprint: %i[name start_date effective_date])
  end

  def agile_sprint_params
    params.permit(sprint: %i[name start_date finish_date])
  end

  def edit_agile_sprint_params
    params.permit(sprint: %i[id name start_date finish_date])
  end

  def converted_agile_sprint_params
    # Do some preprocessing to make the params easier to use
    converted_sprint_params = agile_sprint_params[:sprint].to_h
    converted_sprint_params[:project] = @project

    converted_sprint_params
  end
end
