require 'faraday'

RSpec.describe "The pact provider verifier" do
  it "verifies the given pact against a running service" do
    with_process(test_provider_process, false) do
      sleep 2

      Bundler.with_unbundled_env do
        output = `#{pact_verifier_command}`
        puts output
        expect(output).to include "1 interaction, 0 failures"
      end
    end
  end
end
