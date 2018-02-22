require 'filelock'

RSpec.describe "testing locking" do
  it "" do
    FileUtils.rm_rf "foo"
    File.open("foo", "w") { |file| file << "content" }
    Filelock("foo") do | file |
      expect(File.read("foo")).to eq "content"
    end
  end
end