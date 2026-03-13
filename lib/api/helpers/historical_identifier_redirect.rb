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

module API
  module Helpers
    module HistoricalIdentifierRedirect
      # Redirects API requests using a historical project identifier to the canonical URL
      # with the project's current identifier.
      #
      # Returns a 301 Moved Permanently response when the request uses a historical
      # (retired) project identifier. This ensures API responses always use canonical URLs.
      #
      # @param identifier_param [Symbol] The route parameter name (e.g., :id, :project, :of)
      # @param project [Project] The loaded project instance
      #
      # @example In a Grape API endpoint
      #   route_param :id do
      #     after_validation do
      #       helpers ::API::Helpers::HistoricalIdentifierRedirect
      #       @project = Project.find(params[:id])
      #       redirect_if_historical_identifier(:id, @project)
      #     end
      #   end
      def redirect_if_historical_identifier(identifier_param, project)
        param_value = params[identifier_param]

        # Only redirect if:
        # 1. The parameter is a friendly_id slug (not numeric ID)
        # 2. The parameter doesn't match the project's current identifier
        if param_value.friendly_id? && param_value != project.identifier
          # Reconstruct the current URL with the new identifier
          # Handle both path parameters (e.g., /workspaces/old-id) and query parameters (e.g., ?of=old-id)
          new_url = request.url.sub(
            /([?&]#{identifier_param}=|\/)(#{Regexp.escape(param_value)})(\b|&|$)/,
            "\\1#{project.identifier}\\3"
          )

          # Return 301 Moved Permanently
          redirect new_url, permanent: true
        end
      end
    end
  end
end
