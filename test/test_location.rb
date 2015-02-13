require 'minitest/autorun'
require 'osc/machete'

class TestLocation < Minitest::Test

  def setup
    @target = Dir.mktmpdir("location")
    @subject = OSC::Machete::Location.new @target
  end

  def teardown
    FileUtils.remove_entry @target
  end

  # Location.render(params, options = {})

  def test_render_default_replace_template
    setup_render
    @subject.render("")
    assert_equal true,  File.exists?("#{@target}/file.txt")
    assert_equal false, File.exists?("#{@target}/file.txt.mustache")
  end

  def test_render_user_replace_template
    setup_render
    @subject.render("", {replace: true})
    assert_equal true,  File.exists?("#{@target}/file.txt")
    assert_equal false, File.exists?("#{@target}/file.txt.mustache")
  end

  def test_render_user_doesnt_replace_template
    setup_render
    @subject.render("", {replace: false})
    assert_equal true,  File.exists?("#{@target}/file.txt")
    assert_equal true,  File.exists?("#{@target}/file.txt.mustache")
  end

  private

    def setup_render
      FileUtils.touch("#{@target}/file.txt.mustache")
    end

end
