task :default do
  puts "Hello world"
end

class GetLatestReleaseAssetUrl

  def self.call release_asset_name_regexp
    require 'octokit'
    stack = Faraday::RackBuilder.new do |builder|
      builder.response :logger do | logger |
        logger.filter(/(Authorization: )(.*)/,'\1[REMOVED]')
      end
      builder.use Octokit::Response::RaiseError
      builder.adapter Faraday.default_adapter
    end
    Octokit.middleware = stack

    access_token = ENV.fetch('GITHUB_ACCESS_TOKEN')
    repository_slug = 'pact-foundation/pact-ruby-standalone'

    client = Octokit::Client.new(access_token: access_token)
    client.connection_options[:ssl] = { :verify => false } #TEMP!!!
    release =  client.latest_release repository_slug
    release_assets = client.release_assets release.url
    zip = release_assets.find { | release_asset | release_asset.name =~ release_asset_name_regexp }
    zip.url
  end

end

class DownloadReleaseAsset

  def self.call url, file_path
    require 'faraday'
    require 'faraday_middleware'

    #TEMP!!! Must turn on verification again
    faraday = Faraday.new(:url => url, :ssl => {verify: false}) do |faraday|
      faraday.use FaradayMiddleware::FollowRedirects
      faraday.adapter Faraday.default_adapter
      faraday.response :logger
    end

    response = faraday.get do | request |
      request.headers['Accept'] = 'application/octet-stream'
    end

    puts "Writing file #{file_path}"
    File.open(file_path, "w") { |file| file << response.body }
    puts "Finished writing file #{file_path}"
  end
end

LOCAL_PACKAGE_LOCATION = "tmp/pact.zip"

desc 'Download latest pact-X.X.X-win32.zip'
task :download_latest_release do |t, args |
  require 'fileutils'
  FileUtils.mkdir_p "tmp"

  url = GetLatestReleaseAssetUrl.call /zip/
  DownloadReleaseAsset.call(url, LOCAL_PACKAGE_LOCATION)
end

task :unzip_package do
  require 'zip'
  require 'pathname'
  puts "Unzipping #{LOCAL_PACKAGE_LOCATION}"
  Zip::File.open(LOCAL_PACKAGE_LOCATION) do |zip_file|
    zip_file.each do |entry|
      puts "Extracting #{File.join("tmp", entry.name)}"
      entry.extract(File.join("tmp", entry.name))
    end
  end
end

task :test do
  require 'childprocess'
  require 'faraday'
  logger = Logger.new($stdout)
  logger.level = Logger::INFO
  ChildProcess.logger = logger
  process = ChildProcess.build("./pact-mock-service.bat", "service", "-p", "1234")

  process.cwd = "tmp/pact/bin"
  process.io.inherit!

  begin
    process.start
    sleep 3

    response = Faraday.get("http://localhost:1234", nil, {'X-Pact-Mock-Service' => 'true'})
    raise "#{response.status} #{response.body}" unless response.status == 200
  ensure
    process.stop
  end
end

task :bethtest do
  require 'childprocess'
  require 'faraday'
  logger = Logger.new($stdout)
  logger.level = Logger::INFO
  ChildProcess.logger = logger
  process = ChildProcess.build("./pact-mock-service", "service", "-p", "1234")

  process.cwd = "osx/pact/bin"
  process.io.inherit!

  begin
    process.start
    sleep 3

    response = Faraday.get("http://localhost:1234", nil, {'X-Pact-Mock-Service' => 'true'})
    raise "#{response.status} #{response.body}" unless response.status == 200
  ensure
    process.stop
  end
end

task :default => [:download_latest_release, :unzip_package, :test]
