# frozen_string_literal: true

# Shared example for controller specs that verify GET requests using a
# historical (stale) project identifier are redirected 301 to the same
# URL with the project's current identifier.
#
# Requires `project` to be defined in the enclosing context (via let).
#
# Usage:
#   it_behaves_like "redirects GET requests using a historical project identifier",
#                   :index, { project_id: :injected_by_shared_example }
#
#   # With extra required params (e.g. forum_id):
#   it_behaves_like "redirects GET requests using a historical project identifier",
#                   :index, { forum_id: -> { forum.id } }
#
# The param key for the project is always :project_id.
# To test with :id instead, use the "...via :id" variant below.
RSpec.shared_examples "redirects GET requests using a historical project identifier" do |action, extra_params = {}|
  let!(:old_identifier) { project.identifier }

  before { project.update!(identifier: "current-identifier") }

  it "redirects to the same action with the current identifier (301)" do
    resolved = extra_params.transform_values { |v| v.respond_to?(:call) ? instance_exec(&v) : v }
    get action, params: { project_id: old_identifier }.merge(resolved)
    expect(response).to have_http_status(:moved_permanently)
    expect(response.location).to include("current-identifier")
  end
end

# Variant for controllers that use :id instead of :project_id for the project param.
RSpec.shared_examples "redirects GET requests using a historical project :id" do |action, extra_params = {}|
  let!(:old_identifier) { project.identifier }

  before { project.update!(identifier: "current-identifier") }

  it "redirects to the same action with the current identifier (301)" do
    resolved = extra_params.transform_values { |v| v.respond_to?(:call) ? instance_exec(&v) : v }
    get action, params: { id: old_identifier }.merge(resolved)
    expect(response).to have_http_status(:moved_permanently)
    expect(response.location).to include("current-identifier")
  end
end
