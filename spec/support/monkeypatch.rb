module Pact
  class ConsumerContractWriter

    def windows?
      (RUBY_PLATFORM =~ /mswin|mingw|bccwin|wince|emx/) != nil
    end

    def with_lockfile pactfile_path
      lockfile_path = windows? ? pactfile_path + ".lock" : pactfile_path
      begin
        puts "Locking #{lockfile_path}"
        Filelock lockfile_path do | locked_file |
          if windows?
            File.open(pactfile_path, "a") { |pact_file| puts "yielding #{pactfile_path}"; yield pact_file }
          else
            puts "yielding #{locked_file.path}"
            yield locked_file
          end
        end
      rescue StandardError => e
        warn_and_stderr("#{e.class} #{e.message}")
        if windows?
          File.unlink(lockfile_path) rescue nil
        end
      end
    end

    def update_pactfile
      logger.info log_message
      FileUtils.mkdir_p File.dirname(pactfile_path)
      with_lockfile(pactfile_path) do | pact_file |
        new_contents = pact_json
        pact_file.truncate 0
        pact_file.write new_contents
      end
    end
  end
end
