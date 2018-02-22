require 'filelock'

RSpec.describe "testing locking" do

  it "" do
    File.open("counter", File::RDWR|File::CREAT, 0644) {|f|
      f.flock(File::LOCK_EX)
      value = f.read.to_i + 1
      f.rewind
      f.write("#{value}\n")
      f.flush
      f.truncate(f.pos)
    }
    expect(File.read("counter")).to eq "1\n"
  end

  it "" do
    FileUtils.rm_rf "foo"
    File.open("foo", "w") { |file| file << "content" }
    Filelock("foo") do | file |
      file.rewind
      expect(file.read).to eq "content"
    end
  end
end