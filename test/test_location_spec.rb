require 'minitest/autorun'
require 'osc/machete'

describe OSC::Machete::Location do

  let(:target) { "LocationTestApp" }

  before do
    Dir.mkdir(target)
  end

  after do
    FileUtils.remove_entry target
  end

  subject { OSC::Machete::Location.new target }

  describe "when rendering a template" do

    before do
      FileUtils.touch("#{target}/file.txt.mustache")
    end

    it "should delete the template by default" do
      subject.render("")
      File.exists?("#{target}/file.txt").must_equal true
      File.exists?("#{target}/file.txt.mustache").must_equal false
    end

    it "should delete the template if user specifies" do
      subject.render("", {options: true})
      File.exists?("#{target}/file.txt").must_equal true
      File.exists?("#{target}/file.txt.mustache").must_equal false
    end

    it "shouldn't delete the template if user specifies" do
      subject.render("", {options: false})
      File.exists?("#{target}/file.txt").must_equal true
      File.exists?("#{target}/file.txt.mustache").must_equal true
    end

  end

end
