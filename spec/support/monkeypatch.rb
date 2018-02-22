def Filelock(lockname, options = {}, &block)
  lockname = lockname.path if lockname.is_a?(Tempfile)
  File.open(lockname, File::RDWR|File::CREAT, 0644) do |file|
    Timeout::timeout(options.fetch(:wait, 60*60*24), Filelock::WaitTimeout) { file.flock(File::LOCK_EX) }
    Timeout::timeout(options.fetch(:timeout, 60), Filelock::ExecTimeout) { yield file; file.flock(File::LOCK_UN) }
  end
end