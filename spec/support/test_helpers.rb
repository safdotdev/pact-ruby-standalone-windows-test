require 'openssl'

module Pact
  module StandaloneWindowsTest
    module TestHelpers

      def windows?
        (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
      end

      def build_process cmd_parts, cwd = nil
        require 'childprocess'
        logger = Logger.new($stdout)
        logger.level = Logger::INFO
        ChildProcess.logger = logger
        process = ChildProcess.build(*cmd_parts)
        process.cwd = cwd if cwd
        process.leader = true if windows? # not sure if we need this
        process.io.inherit!
        process
      end

      def mock_service_process options = {}
        port = options[:port] || "1235"
        cli_args = options[:cli_args] || []
        if windows?
          build_process ["cmd.exe", "/c","pact-mock-service.bat", "service", "-p", port] + cli_args, "tmp/pact/bin"
        else
          # Manually downloaded and extracted, for local testing
          build_process ["./pact-mock-service", "service", "-p", port] + cli_args, "osx/pact/bin"
        end
      end

      def stub_service_process pact_path, options = {}
        port = options[:port] || "1236"
        cli_args = options[:cli_args] || []
        if windows?
          build_process ["cmd.exe", "/c","pact-stub-service.bat", pact_path, "-p", port] + cli_args, "tmp/pact/bin"
        else
          # Manually downloaded and extracted, for local testing
          build_process ["./pact-stub-service", pact_path, "-p", port] + cli_args, "osx/pact/bin"
        end
      end

      def test_provider_process
        if windows?
          build_process ["cmd.exe", "/c","bundle", "exec", "rackup", "-p", "1236", "test/config.ru"]
        else
          build_process ["ruby", "-S", "bundle", "exec", "rackup", "-p", "1236", "test/config.ru"]
        end
      end

      def pact_verifier_command
        suffix = "verify #{File.absolute_path("test/pact.json")} --provider-base-url http://localhost:1236"
        if windows?
          "cd tmp/pact/bin && cmd.exe /c pact-provider-verifier.bat #{suffix}"
        else
          # Manually downloaded and extracted, for local testing
          "cd osx/pact/bin && ./pact-provider-verifier #{suffix}"
        end
      end

      def with_process process, clean_env = true
        if clean_env
          Bundler.with_clean_env do
            process.start
          end
        else
          process.start
        end
        yield
      ensure
        process.stop if process && process.alive?
      end

      def expect_successful_request faraday, http_method, path, body = nil, headers = {}
        response = faraday.send(http_method, path, body, headers)
        raise "#{response.status} #{response.body}" unless response.status == 200
        response
      end

      def wait_for_mock_service_to_start faraday, admin_headers
        i = 0
        while true
          begin
            faraday.get("/", nil, admin_headers)
            return true
          rescue Faraday::ConnectionFailed => e
            i += 1
            sleep 1
            retry if i < 15
            raise e
          end
        end
      end
    end
  end
end

