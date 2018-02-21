require 'faraday'
require 'json'

RSpec.describe "Running the mock service with --pact-file-mode merge" do

  let(:pact_file_path) { "./pacts/foo-bar.json" }

  let(:faraday) do
    Faraday.new(:url => "http://localhost:1235") do |faraday|
      faraday.adapter Faraday.default_adapter
      faraday.response :logger do | logger |
        def logger.debug *args; end
      end
    end
  end

  let(:mock_service_options) do
    { cli_args: ['--pact-file-write-mode', 'merge'] }
  end

  let(:first_interaction) do
    {description: "test", providerState: nil, request: {method: 'GET', path: '/test'}, response: {status: 200} }
  end

  let(:second_interaction) do
    {description: "another test", providerState: nil, request: {method: 'GET', path: '/another-test'}, response: {status: 200} }
  end

  let(:interaction_headers) do
    {'X-Pact-Mock-Service' => 'true', 'Content-Type' => 'application/json'}
  end

  let(:admin_header) do
    {'X-Pact-Mock-Service' => 'true'}
  end

  let(:pact_details) do
    { consumer: { name: 'Foo' }, provider: { name: 'bar' }, pact_dir: File.absolute_path('./pacts') }
  end

  let(:pact_hash) do
    JSON.parse(File.read(pact_file_path), symbolize_names: true)
  end

  it "creates a file when one does not already exist" do
    FileUtils.rm_rf pact_file_path
    with_process(mock_service_process(mock_service_options)) do
      wait_for_mock_service_to_start(faraday, admin_header)
      expect_successful_request(faraday, :get,  "/", nil, admin_header)
      expect_successful_request(faraday, :post, "/interactions", first_interaction.to_json, interaction_headers)
      expect_successful_request(faraday, :get,  "/test")
      expect_successful_request(faraday, :get,  "/interactions/verification", nil, admin_header)
      expect_successful_request(faraday, :post, "/pact", pact_details.to_json, admin_header)
      expect(File.exists?(pact_file_path))
    end
  end

  it "merges the interaction into the existing file when the pact file exists" do
    with_process(mock_service_process(mock_service_options)) do
      wait_for_mock_service_to_start(faraday, admin_header)
      expect_successful_request(faraday, :get,  "/", nil, admin_header)
      expect_successful_request(faraday, :post, "/interactions", second_interaction.to_json, interaction_headers)
      expect_successful_request(faraday, :get,  "/another-test")
      expect_successful_request(faraday, :get,  "/interactions/verification", nil, admin_header)
      expect_successful_request(faraday, :post, "/pact", pact_details.to_json, admin_header)
      expect(pact_hash[:interactions].size).to eq 2
    end
  end
end
