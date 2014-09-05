require 'minitest/autorun'
require 'osc/machete'

describe OSC::Machete::JobDir do

  let(:target) { "App123" }

  before do
    Dir.mkdir(target)
  end

  after do
    FileUtils.remove_entry target
  end

  subject { OSC::Machete::JobDir.new target }

  describe "when numbered file greater than directory numbers" do

    before do
      Dir.mkdir("#{target}/1")
      Dir.mkdir("#{target}/5")
      FileUtils.touch("#{target}/8")
    end

    specify "a unique directory should be created incremented up from file number" do
      new_jobdir = subject.new_jobdir
      Dir.mkdir(new_jobdir)
      Dir.exists?("#{target}/9").must_equal true
    end

  end

end
