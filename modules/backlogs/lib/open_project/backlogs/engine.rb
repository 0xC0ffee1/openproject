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

require "open_project/plugins"
require_relative "patches/api/work_package_representer"
require_relative "patches/api/work_package_schema_representer"

module OpenProject::Backlogs
  class Engine < ::Rails::Engine
    engine_name :openproject_backlogs

    def self.settings
      {
        default: {
          "story_types" => nil,
          "task_type" => nil,
          "points_burn_direction" => "up",
          "wiki_template" => ""
        },
        menu_item: :backlogs_settings
      }
    end

    include OpenProject::Plugins::ActsAsOpEngine

    register("openproject-backlogs",
             author_url: "https://www.openproject.org",
             bundled: true,
             settings:) do
      Rails.application.reloader.to_prepare do
        OpenProject::AccessControl.permission(:add_work_packages).tap do |add|
          add.controller_actions << "rb_tasks/create"
          add.controller_actions << "rb_impediments/create"
        end

        OpenProject::AccessControl.permission(:edit_work_packages).tap do |edit|
          edit.controller_actions << "rb_tasks/update"
          edit.controller_actions << "rb_impediments/update"
        end
      end

      project_module :backlogs, dependencies: :work_package_tracking do
        permission :view_sprints,
                   { rb_master_backlogs: %i[index details],
                     rb_sprints: %i[index show show_name],
                     rb_wikis: :show,
                     rb_stories: %i[index show],
                     rb_queries: :show,
                     rb_burndown_charts: :show,
                     rb_taskboards: :show,
                     rb_tasks: %i[index show],
                     rb_impediments: %i[index show] },
                   permissible_on: :project,
                   dependencies: :view_work_packages

        permission :select_done_statuses,
                   {
                     "projects/settings/backlogs": %i[show update rebuild_positions]
                   },
                   permissible_on: :project,
                   require: :member

        permission :create_sprints,
                   { rb_sprints: %i[new_dialog refresh_form create edit_name update edit_dialog update_agile_sprint],
                     rb_wikis: %i[edit update] },
                   permissible_on: :project,
                   require: :member,
                   dependencies: :view_sprints

        permission :start_complete_sprint,
                   {},
                   permissible_on: :project,
                   require: :member,
                   dependencies: :view_sprints,
                   visible: -> { OpenProject::FeatureDecisions.scrum_projects_active? }

        permission :manage_sprint_items,
                   { rb_stories: %i[move reorder] },
                   permissible_on: :project,
                   require: :member,
                   dependencies: :view_sprints

        permission :share_sprint,
                   {},
                   permissible_on: :project,
                   require: :member,
                   dependencies: :create_sprints,
                   visible: -> { OpenProject::FeatureDecisions.scrum_projects_active? }
      end

      menu :project_menu,
           :backlogs,
           { controller: "/rb_master_backlogs", action: :index },
           caption: :project_module_backlogs,
           after: :work_packages,
           icon: "op-backlogs"

      menu :project_menu,
           :settings_backlogs,
           { controller: "/projects/settings/backlogs", action: :show },
           caption: :label_backlogs,
           parent: :settings,
           before: :settings_storage
    end

    patches %i[PermittedParams
               WorkPackage
               Status
               Type
               Project
               User
               VersionsController
               Version]

    patch_with_namespace :BasicData, :SettingSeeder
    patch_with_namespace :DemoData, :ProjectSeeder
    patch_with_namespace :WorkPackages, :UpdateService
    patch_with_namespace :WorkPackages, :SetAttributesService
    patch_with_namespace :WorkPackages, :BaseContract
    patch_with_namespace :WorkPackages, :UpdateContract
    patch_with_namespace :Versions, :RowComponent
    patch_with_namespace :API, :V3, :WorkPackages, :EagerLoading, :Checksum

    config.to_prepare do
      next if Versions::BaseContract.include?(OpenProject::Backlogs::Patches::Versions::BaseContractPatch)

      Versions::BaseContract.prepend(OpenProject::Backlogs::Patches::Versions::BaseContractPatch)

      # Add available settings to the user preferences
      UserPreferences::Schema.merge!(
        "definitions/UserPreferences/properties",
        {
          "backlogs_task_color" => {
            "type" => "string"
          },
          "backlogs_versions_default_fold_state" => {
            "type" => "string",
            "enum" => %w[open closed]
          }
        }
      )
    end

    extend_api_response(:v3, :work_packages, :work_package,
                        &::OpenProject::Backlogs::Patches::API::WorkPackageRepresenter.extension)

    # TODO: check if this can be simply removed as it already gets its info by patching the WPRepresenter
    extend_api_response(:v3, :work_packages, :work_package_payload,
                        &::OpenProject::Backlogs::Patches::API::WorkPackageRepresenter.extension)

    extend_api_response(:v3, :work_packages, :schema, :work_package_schema,
                        &::OpenProject::Backlogs::Patches::API::WorkPackageSchemaRepresenter.extension)

    add_api_path :backlogs_type do |id|
      # There is no api endpoint for this url
      "#{root}/backlogs_types/#{id}"
    end

    add_api_path :sprint do |id|
      "#{root}/sprints/#{id}"
    end

    add_api_path :sprints do
      "#{root}/sprints"
    end

    add_api_path :project_sprints do |id|
      "#{root}/projects/#{id}/sprints"
    end

    add_api_endpoint "API::V3::Root" do
      mount ::API::V3::Sprints::SprintsAPI
    end

    add_api_endpoint "API::V3::Projects::ProjectsAPI", :id do
      mount ::API::V3::Sprints::SprintsByProjectAPI
    end

    config.to_prepare do
      OpenProject::Backlogs::Hooks::LayoutHook
      OpenProject::Backlogs::Hooks::UserSettingsHook
    end

    config.to_prepare do
      enabled_backlogs_story = ->(type, project: nil) do
        if project.present?
          project.backlogs_enabled? && type.story?
        else
          # Allow globally configuring the attribute if story
          type.story?
        end
      end

      story_and_sprint_permission = ->(type, project: nil) do
        if project.present?
          type.story? && User.current.allowed_in_project?(:view_sprints, project)
        else
          # Allow globally configuring the attribute if story
          type.story?
        end
      end

      ::Type.add_constraint :position, enabled_backlogs_story
      ::Type.add_constraint :story_points, enabled_backlogs_story
      ::Type.add_constraint :sprint, story_and_sprint_permission

      ::Type.add_default_mapping(:estimates_and_progress, :story_points)
      ::Type.add_default_mapping(:other, :position)

      ::Queries::Register.register(::Query) do
        filter OpenProject::Backlogs::WorkPackageFilter

        select OpenProject::Backlogs::QueryBacklogsSelect
      end
    end
  end
end
