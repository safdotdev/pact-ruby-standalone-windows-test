require 'openssl'

LOCAL_PACKAGE_LOCATION = "tmp/pact.zip".freeze
SSL_OPTIONS = {ca_file: 'cacert.pem', cert_store: OpenSSL::X509::Store.new}.freeze

def windows?
  (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
end

def github_access_token
  ENV.fetch('GITHUB_ACCESS_TOKEN')
end

def get_latest_release_asset_url release_asset_name_regexp
  require 'octokit'
  stack = Faraday::RackBuilder.new do |builder|
    builder.response :logger do | logger |
      logger.filter(/(Authorization: )(.*)/,'\1[REMOVED]')
    end
    builder.use Octokit::Response::RaiseError
    builder.adapter Faraday.default_adapter
  end
  Octokit.middleware = stack

  repository_slug = 'pact-foundation/pact-ruby-standalone'

  client = Octokit::Client.new(access_token: github_access_token)
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
    end
  end

  response = faraday.get do | request |
    request.headers['Accept'] = 'application/octet-stream'
    request.headers['Authorization'] = "token #{github_access_token}"
  end
  raise "Expected response status 302 but got #{response.status}" unless response.status == 302

  response = Faraday.get(response.headers['Location'])
  raise "Error downloading release" unless response.status == 200

  puts "Writing file #{file_path}"
  File.open(file_path, "wb") { |file| file << response.body }
  puts "Finished writing file #{file_path}"
end

def unzip_package path
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

def build_process
  require 'childprocess'

  logger = Logger.new($stdout)
  logger.level = Logger::INFO
  ChildProcess.logger = logger
  if windows?
    process = ChildProcess.build("cmd.exe", "/c","pact-mock-service.bat", "service", "-p", "1235")
    process.cwd = "tmp/pact/bin"
    process.leader = true # not sure if we need this
  else
    # Manually downloaded and extracted, for local testing
    process = ChildProcess.build("./pact-mock-service", "service", "-p", "1235")
    process.cwd = "osx/pact/bin"
  end

  process.io.inherit!
  process
end

def test_executable
  require 'faraday'

  process = build_process

  Bundler.with_clean_env do
    process.start
  end
  sleep 3

  response = Faraday.get("http://localhost:1235", nil, {'X-Pact-Mock-Service' => 'true'})
  puts response.body
  raise "#{response.status} #{response.body}" unless response.status == 200
ensure
  process.stop if process && process.alive?
end

desc 'Download latest pact-X.X.X-win32.zip'
task :download_latest_release do |t, args |
  begin
    require 'fileutils'
    FileUtils.rm_rf "tmp"
    FileUtils.mkdir_p "tmp"

    url = get_latest_release_asset_url /win.*zip/
    download_release_asset url, LOCAL_PACKAGE_LOCATION

  rescue StandardError => e
    # Appveyor doesn't display stderr in a helpful way, need to manually print error
    puts "#{e.class} #{e.message} #{e.backtrace.join("\n")}"
    raise e
  end
end

desc 'Unzip package'
task :unzip_package do
  unzip_package LOCAL_PACKAGE_LOCATION
end

desc 'Test windows batch file'
task :test do
  begin
    test_executable
  rescue StandardError => e
    # Appveyor doesn't display stderr in a helpful way, need to manually print error
    puts "#{e.class} #{e.message} #{e.backtrace.join("\n")}"
    raise e
  end
end

task :default => [:download_latest_release, :unzip_package, :test]
