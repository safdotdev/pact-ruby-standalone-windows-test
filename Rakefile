require 'openssl'
require 'rspec/core/rake_task'
require './tasks/support'

RSpec::Core::RakeTask.new(:spec)

desc 'Download latest pact-X.X.X-win32.zip'
task :download_latest_release do |t, args |
  include Pact::StandaloneWindowsTest::Setup
  download_latest_release
end

desc 'Unzip package'
task :unzip_package do
  include Pact::StandaloneWindowsTest::Setup
  unzip_package
end

task :default => [:download_latest_release, :unzip_package, :spec]
