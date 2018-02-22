
module Pact
  class ConsumerContractWriter

    def update_pactfile
      puts "Updating pact file with lock on separate file"
      logger.info log_message
      FileUtils.mkdir_p File.dirname(pactfile_path)
      lockfile_path = pactfile_path + ".lock"
      Filelock lockfile_path do | file |
        new_contents = pact_json
        File.open(pactfile_path, "w") { |file| file << new_contents }
      end
    end

  end
end


# def Filelock(lockname, options = {}, &block)
#   lockname = lockname.path if lockname.is_a?(Tempfile)
#   File.open(lockname, File::RDWR|File::CREAT, 0644) do |file|
#     Timeout::timeout(options.fetch(:wait, 60*60*24), Filelock::WaitTimeout) { file.flock(File::LOCK_EX) }
#     Timeout::timeout(options.fetch(:timeout, 60), Filelock::ExecTimeout) { yield file; file.flock(File::LOCK_UN) }
#   end
# end