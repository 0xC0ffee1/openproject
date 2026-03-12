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

require "rails_helper"

RSpec.describe RbSprintsController do
  describe "new actions" do
    shared_let(:type_feature) { create(:type_feature) }
    shared_let(:type_task) { create(:type_task) }

    let(:all_permissions) { %i[view_sprints view_work_packages create_sprints] }
    let(:permissions) { all_permissions }
    let(:user) do
      create(:user, member_with_permissions: { project => permissions })
    end
    let(:project) { create(:project) }

    current_user { user }

    before do
      # Necessary to get the controller running due to check_if_plugin_is_configured
      allow(Setting)
        .to receive(:plugin_openproject_backlogs)
              .and_return({ "story_types" => [type_feature.id], "task_type" => type_task.id })
    end

    describe "GET #new_dialog" do
      context "with the feature flag inactive" do
        it "responds with forbidden" do
          get :new_dialog, params: { project_id: project.id }, format: :turbo_stream

          expect(response).not_to be_successful
          expect(response).to have_http_status :forbidden
        end
      end

      context "with the feature flag active", with_flag: { scrum_projects: true } do
        it "responds with success", :aggregate_failures do
          get :new_dialog, params: { project_id: project.id }, format: :turbo_stream

          expect(response).to be_successful
          expect(response).to have_http_status :ok
          expect(response).to have_turbo_stream action: "dialog", target: "backlogs-new-sprint-dialog-component"
          expect(assigns(:project)).to eq(project)
        end

        context "without the 'create_sprints' permission" do
          let(:permissions) { all_permissions - [:create_sprints] }

          it "responds with forbidden", :aggregate_failures do
            get :new_dialog, params: { project_id: project.id }, format: :turbo_stream

            expect(response).not_to be_successful
            expect(response).to have_http_status :forbidden
          end
        end
      end
    end

    describe "GET #edit_dialog" do
      let!(:sprint) { create(:agile_sprint, project:) }

      context "with the feature flag inactive" do
        it "responds with forbidden" do
          get :edit_dialog, params: { project_id: project.id, id: sprint.id }, format: :turbo_stream

          expect(response).not_to be_successful
          expect(response).to have_http_status :forbidden
        end
      end

      context "with the feature flag active", with_flag: { scrum_projects: true } do
        it "responds with success", :aggregate_failures do
          get :edit_dialog, params: { project_id: project.id, id: sprint.id }, format: :turbo_stream

          expect(response).to be_successful
          expect(response).to have_http_status :ok
          expect(response).to have_turbo_stream action: "dialog", target: "backlogs-new-sprint-dialog-component"
          expect(assigns(:project)).to eq(project)
          expect(assigns(:sprint)).to eq(sprint)
        end

        context "without the 'create_sprints' permission" do
          let(:permissions) { all_permissions - [:create_sprints] }

          it "responds with forbidden", :aggregate_failures do
            get :edit_dialog, params: { project_id: project.id, id: sprint.id }, format: :turbo_stream

            expect(response).not_to be_successful
            expect(response).to have_http_status :forbidden
          end
        end
      end
    end

    describe "POST #create" do
      context "with the feature flag inactive" do
        it "responds with forbidden" do
          post :create, params: { project_id: project.id }, format: :turbo_stream

          expect(response).not_to be_successful
          expect(response).to have_http_status :forbidden
        end
      end

      context "with the feature flag active", with_flag: { scrum_projects: true } do
        let(:params) do
          {
            project_id: project.id,
            sprint: { name: "My Sprint", start_date: "2025-10-05", finish_date: "2025-10-15" }
          }
        end

        it "responds with success, creates a sprint, and redirects to backlogs", :aggregate_failures do
          post :create, format: :turbo_stream, params: params

          expect(response).to be_successful
          expect(response).to have_http_status :ok
          expect(response.body).to include("turbo-stream")
          expect(response.body).to include("action=\"redirect_to\"")
          expect(response.body).to include(backlogs_project_backlogs_path(project))
          expect(project.reload.sprints.last.name).to eq("My Sprint")
          expect(flash[:notice]).to eq(I18n.t(:notice_successful_create))
        end

        context "without the 'create_sprints' permission" do
          let(:permissions) { all_permissions - [:create_sprints] }

          it "responds with forbidden", :aggregate_failures do
            post :create, format: :turbo_stream, params: params

            expect(response).not_to be_successful
            expect(response).to have_http_status :forbidden
          end
        end
      end
    end

    describe "PUT #update_agile_sprint" do
      let!(:sprint) { create(:agile_sprint, name: "Original sprint name", project:) }

      context "with the feature flag inactive" do
        it "responds with forbidden" do
          put :update_agile_sprint, params: { id: sprint.id, project_id: project.id }, format: :turbo_stream

          expect(response).not_to be_successful
          expect(response).to have_http_status :forbidden
        end
      end

      context "with the feature flag active", with_flag: { scrum_projects: true } do
        let(:params) do
          {
            id: sprint.id,
            project_id: project.id,
            sprint: { name: "Changed sprint name" }
          }
        end

        it "responds with success", :aggregate_failures do
          put :update_agile_sprint, format: :turbo_stream, params: params

          expect(response).to be_successful
          expect(response).to have_http_status :ok
          expect(response.body).to have_turbo_stream action: "flash"
          expect(response.body).to include("Successful update.")
          expect(sprint.reload.name).to eq("Changed sprint name")
        end

        context "without the 'create_sprints' permission" do
          let(:permissions) { all_permissions - [:create_sprints] }

          it "responds with forbidden", :aggregate_failures do
            put :update_agile_sprint, format: :turbo_stream, params: params

            expect(response).not_to be_successful
            expect(response).to have_http_status :forbidden
          end
        end
      end
    end

    describe "GET #refresh_form" do
      context "with the feature flag inactive" do
        it "responds with forbidden" do
          get :refresh_form, params: { project_id: project.id }, format: :turbo_stream

          expect(response).not_to be_successful
          expect(response).to have_http_status :forbidden
        end
      end

      context "with the feature flag active", with_flag: { scrum_projects: true } do
        let(:params) do
          {
            project_id: project.id,
            sprint: { name: "My Sprint", start_date: "2025-10-05", finish_date: "2025-10-15" }
          }
        end

        it "responds with success", :aggregate_failures do
          get :refresh_form, format: :turbo_stream, params: params

          expect(response).to be_successful
          expect(response).to have_http_status :ok
          expect(response).to have_turbo_stream action: "update", target: "backlogs-new-sprint-form-component"
          expect(assigns(:sprint)).to be_nil
        end

        context "without the 'create_sprints' permission" do
          let(:permissions) { all_permissions - [:create_sprints] }

          it "responds with forbidden", :aggregate_failures do
            get :refresh_form, format: :turbo_stream, params: params

            expect(response).not_to be_successful
            expect(response).to have_http_status :forbidden
          end
        end

        context "when refreshing the form in edit mode by passing a sprint id" do
          let!(:sprint) { create(:agile_sprint, project:) }
          let(:params) do
            {
              project_id: project.id,
              sprint: { id: sprint.id, name: "My Sprint", start_date: "2025-10-05", finish_date: "2025-10-15" }
            }
          end

          it "responds with success", :aggregate_failures do
            get :refresh_form, format: :turbo_stream, params: params

            expect(response).to be_successful
            expect(response).to have_http_status :ok
            expect(response).to have_turbo_stream action: "update", target: "backlogs-new-sprint-form-component"
          end
        end
      end
    end
  end

  describe "legacy actions" do
    shared_let(:type_feature) { create(:type_feature) }
    shared_let(:type_task) { create(:type_task) }
    shared_let(:user) { create(:admin) }
    current_user { user }

    let(:visible_projects_scope) { instance_double(ActiveRecord::Relation) }
    let(:visible_sprints_scope) { instance_double(ActiveRecord::Relation) }

    before do
      allow(Setting)
        .to receive(:plugin_openproject_backlogs)
              .and_return({ "story_types" => [type_feature.id], "task_type" => type_task.id })

      allow(Project)
        .to receive(:visible)
              .and_return(visible_projects_scope)

      allow(visible_projects_scope)
        .to receive(:find)
              .with(project.identifier)
              .and_return(project)

      allow(Sprint)
        .to receive(:visible)
              .and_return(visible_sprints_scope)

      allow(visible_sprints_scope)
        .to receive(:find)
              .with(sprint.id.to_s)
              .and_return(sprint)
    end

    describe "GET #edit_name" do
      let(:project) { build_stubbed(:project) }
      let(:sprint) { build_stubbed(:sprint) }

      it "responds with success", :aggregate_failures do
        get :edit_name, params: { project_id: project.identifier, id: sprint.id }, format: :turbo_stream

        expect(response).to be_successful
        expect(response).to have_http_status :ok
        expect(response).to have_turbo_stream action: "update", target: "backlogs-backlog-header-component-#{sprint.id}"
        expect(assigns(:project)).to eq(project)
        expect(assigns(:sprint)).to eq(sprint)
        expect(assigns(:backlog)).to be_a(Backlog)
      end
    end

    describe "GET #show_name" do
      let(:project) { build_stubbed(:project) }
      let(:sprint) { build_stubbed(:sprint) }

      it "responds with success", :aggregate_failures do
        get :show_name, params: { project_id: project.identifier, id: sprint.id }, format: :turbo_stream

        expect(response).to be_successful
        expect(response).to have_http_status :ok
        expect(response).to have_turbo_stream action: "update", target: "backlogs-backlog-header-component-#{sprint.id}"
        expect(assigns(:project)).to eq(project)
        expect(assigns(:sprint)).to eq(sprint)
        expect(assigns(:backlog)).to be_a(Backlog)
      end
    end

    describe "PATCH #update" do
      let(:project) { build_stubbed(:project) }
      let(:sprint) { build_stubbed(:sprint) }

      before do
        update_service = instance_double(Versions::UpdateService, call: service_result)

        allow(Versions::UpdateService)
          .to receive(:new)
                .with(user:, model: sprint)
                .and_return(update_service)
      end

      context "when service call succeeds" do
        let(:service_result) { ServiceResult.success(result: sprint) }

        it "responds with success", :aggregate_failures do
          patch :update,
                params: { project_id: project.identifier, id: sprint.id, sprint: { name: "Updated Sprint" } },
                format: :turbo_stream

          expect(response).to be_successful
          expect(response).to have_http_status :ok
          expect(response).to have_turbo_stream action: "update", target: "backlogs-backlog-header-component-#{sprint.id}"
          expect(response).to have_turbo_stream action: "flash", target: "op-primer-flash-component"
          expect(assigns(:project)).to eq(project)
          expect(assigns(:sprint)).to eq(sprint)
          expect(assigns(:backlog)).to be_a(Backlog)
        end
      end

      context "when service call fails" do
        let(:service_result) { ServiceResult.failure(result: sprint) }

        before do
          project.name = ""
        end

        it "responds with 422", :aggregate_failures do
          patch :update,
                params: { project_id: project.identifier, id: sprint.id, sprint: { name: "" } },
                format: :turbo_stream

          expect(response).not_to be_successful
          expect(response).to have_http_status :unprocessable_entity
          expect(response).to have_turbo_stream action: "update", target: "backlogs-backlog-header-component-#{sprint.id}"
          expect(response).to have_turbo_stream action: "flash", target: "op-primer-flash-component"
          expect(assigns(:project)).to eq(project)
          expect(assigns(:sprint)).to eq(sprint)
          expect(assigns(:backlog)).to be_a(Backlog)
        end
      end
    end
  end

  describe "stale identifier handling" do
    let(:user) { create(:user, member_with_permissions: { project => %i[view_sprints create_sprints] }) }
    let(:project) { create(:project) }
    let!(:old_identifier) { project.identifier }

    before do
      login_as(user)
      project.update!(identifier: "current-identifier")
      allow(Setting)
        .to receive(:plugin_openproject_backlogs)
              .and_return({ "story_types" => [1], "task_type" => 2 })
    end

    it "does not redirect turbo_stream requests with historical identifier" do
      get :new_dialog, params: { project_id: old_identifier }, format: :turbo_stream
      expect(response).to be_successful
      expect(response).not_to have_http_status(:moved_permanently)
    end
  end
end
