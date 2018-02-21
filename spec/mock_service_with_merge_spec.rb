require 'faraday'
require 'json'
RSpec.describe "running the mock service with the pact-file-mode merge" do

  PACT_FILE_PATH = "./pacts/foo-bar.json"

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
    JSON.parse(File.read(PACT_FILE_PATH), symbolize_names: true)
  end

  it "creates a file when one does not already exist" do
    FileUtils.rm_rf PACT_FILE_PATH
    with_process(mock_service_process(mock_service_options)) do
      wait_for_mock_service_to_start(faraday, admin_header)
      expect_successful_request(faraday, :get,  "/", nil, admin_header)
      expect_successful_request(faraday, :post, "/interactions", first_interaction.to_json, interaction_headers)
      expect_successful_request(faraday, :get,  "/test")
      expect_successful_request(faraday, :get,  "/interactions/verification", nil, admin_header)
      expect_successful_request(faraday, :post, "/pact", pact_details.to_json, admin_header)
      expect(File.exists?(PACT_FILE_PATH))
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
