require "bundler/setup"
require "support/test_helpers"

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"

  config.disable_monkey_patching!

  config.include Pact::StandaloneWindowsTest::TestHelpers

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
