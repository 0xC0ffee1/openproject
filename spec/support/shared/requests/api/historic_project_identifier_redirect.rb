# frozen_string_literal: true

# Shared example for API request specs that verify GET requests using a
# historical (stale) project identifier are redirected 301 to the same
# URL with the project's current identifier.
#
# Requires `project` and `current_user` to be defined in the enclosing context (via let).
#
# Usage:
#   it_behaves_like "API redirects GET requests using a historical project identifier",
#                   "/api/v3/workspaces/:id"
#
#   # With path that includes the identifier in a different position:
#   it_behaves_like "API redirects GET requests using a historical project identifier",
#                   "/api/v3/work_packages/schemas/:id-#{type.id}"
#
# The :id in the path will be replaced with old_identifier for testing.
RSpec.shared_examples "API redirects GET requests using a historical project identifier" do |path_template|
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let!(:old_identifier) { project.identifier }

  before { project.update!(identifier: "current-identifier") }

  it "redirects to the same path with the current identifier (301)" do
    # Replace :id in template with old_identifier
    test_path = path_template.gsub(":id", old_identifier)

    get test_path

    expect(last_response).to have_http_status(301)
    expect(last_response.location).to include("current-identifier")
    expect(last_response.location).not_to include(old_identifier)
  end

  it "does not redirect when using current identifier" do
    test_path = path_template.gsub(":id", "current-identifier")

    get test_path

    expect(last_response).to have_http_status(200)
  end

  it "does not redirect when using numeric ID" do
    test_path = path_template.gsub(":id", project.id.to_s)

    get test_path

    expect(last_response).to have_http_status(200)
  end
end

# Variant for API endpoints with dynamic paths that need let variables
# Requires `path_with_old_id` and `current_identifier_pattern` to be defined via let.
RSpec.shared_examples "API redirects GET requests using a historical project identifier with dynamic path" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let!(:old_identifier) { project.identifier }

  before { project.update!(identifier: "current-identifier") }

  it "redirects to the same path with the current identifier (301)" do
    get path_with_old_id

    expect(last_response).to have_http_status(301)
    expect(last_response.location).to include(current_identifier_pattern)
    expect(last_response.location).not_to include(old_identifier)
  end

  it "does not redirect when using current identifier" do
    path_with_current_id = path_with_old_id.gsub(old_identifier, "current-identifier")
    get path_with_current_id

    expect(last_response).to have_http_status(200)
  end

  it "does not redirect when using numeric ID" do
    path_with_numeric_id = path_with_old_id.gsub(old_identifier, project.id.to_s)
    get path_with_numeric_id

    expect(last_response).to have_http_status(200)
  end
end

# Variant for API endpoints that use query parameters for the project identifier
RSpec.shared_examples "API redirects GET requests using a historical project identifier in query param" do |base_path, param_name|
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let!(:old_identifier) { project.identifier }

  before { project.update!(identifier: "current-identifier") }

  it "redirects to the same path with the current identifier (301)" do
    get "#{base_path}?#{param_name}=#{old_identifier}"

    expect(last_response).to have_http_status(301)
    expect(last_response.location).to include("#{param_name}=current-identifier")
    expect(last_response.location).not_to include(old_identifier)
  end

  it "does not redirect when using current identifier" do
    get "#{base_path}?#{param_name}=current-identifier"

    expect(last_response).to have_http_status(200)
  end
end
