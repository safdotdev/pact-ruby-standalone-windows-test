module Pact
  module StandaloneWindowsTest
    module Setup

      LOCAL_PACKAGE_LOCATION = "tmp/pact.zip".freeze
      # Simulate a Windows environment on Mac by giving it an empty cert_store
      SSL_OPTIONS = {ca_file: 'cacert.pem', cert_store: OpenSSL::X509::Store.new}.freeze

      def windows?
        (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
      end

      def github_access_token
        ENV.fetch('GITHUB_ACCESS_TOKEN')
      end

      def download_latest_release pattern = /windows-x86_64.*zip/
        begin
          require 'fileutils'
          FileUtils.rm_rf "tmp"
          FileUtils.mkdir_p "tmp"

          url = get_latest_release_asset_url pattern
          download_release_asset url, LOCAL_PACKAGE_LOCATION

        rescue StandardError => e
          # Appveyor doesn't display stderr in a helpful way, need to manually print error
          puts "#{e.class} #{e.message} #{e.backtrace.join("\n")}"
          raise e
        end
      end

      def get_latest_release_asset_url release_asset_name_regexp
        require 'octokit'
        stack = Faraday::RackBuilder.new do |builder|
          builder.response :logger do | logger |
            logger.filter(/(Authorization: )(.*)/,'\1[REMOVED]')
            def logger.debug *args; end
          end
          builder.use Octokit::Response::RaiseError
          builder.adapter Faraday.default_adapter
        end
        Octokit.middleware = stack

        repository_slug = 'pact-foundation/pact-ruby-standalone'

        client = Octokit::Client.new()
        client.connection_options[:ssl] = SSL_OPTIONS
        release =  client.latest_release repository_slug
        release_assets = client.release_assets release.url
        zip = release_assets.find { | release_asset | release_asset.name =~ release_asset_name_regexp }
        zip.url
      end

      def download_release_asset url, file_path
        require 'faraday'

        faraday = Faraday.new(:url => url, :ssl => SSL_OPTIONS) do |faraday|
          faraday.adapter Faraday.default_adapter
          faraday.response :logger do | logger |
            logger.filter(/(Authorization: )(.*)/,'\1[REMOVED]')
            def logger.debug *args; end
          end
        end

        response = faraday.get do | request |
          request.headers['Accept'] = 'application/octet-stream'
          # request.headers['Authorization'] = "token #{github_access_token}"
        end
        raise "Expected response status 302 but got #{response.status}" unless response.status == 302

        faraday = Faraday.new(:url => response.headers['Location'], :ssl => SSL_OPTIONS)
        response = faraday.get
        raise "Error downloading release" unless response.status == 200

        puts "Writing file #{file_path}"
        File.open(file_path, "wb") { |file| file << response.body }
        puts "Finished writing file #{file_path}"
      end

      def unzip_package path = LOCAL_PACKAGE_LOCATION
        require 'zip'
        require 'pathname'

        puts "Unzipping #{path}"
        Zip::File.open(path) do |zip_file|
          zip_file.each do |entry|
            entry.extract(File.join("tmp", entry.name))
          end
        end
        puts "Finished unzipping #{path}"
      end
    end

  end
end
