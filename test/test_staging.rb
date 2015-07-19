require 'minitest/autorun'
require 'osc/machete'
require 'yaml'
require 'tmpdir'

class TestStaging < Minitest::Test
  def setup
    
    # test staging using HSP template
    @params = YAML.load(File.read('test/fixtures/app-params.yml'))
    @template = 'test/fixtures/app-template'
    @expected = 'test/fixtures/app-template-rendered'
    
    # directory where to create jobs
    # 
    @target = File.realpath Dir.mktmpdir
    @script = 'GLO_job'
  end
  
  def teardown
    FileUtils.remove_entry @target
  end
  
  def test_template_rendering
    staging = OSC::Machete::Staging.new @template, @target, @script
    job = staging.new_job @params
    
    assert_equal "", `diff -r #{job.path} #{@expected}`
    assert_equal "1", Pathname.new(job.path).basename.to_s
    
    job = staging.new_job @params
    assert_equal "2", Pathname.new(job.path).basename.to_s
    job = staging.new_job @params
    assert_equal "3", Pathname.new(job.path).basename.to_s
    
    Dir.mkdir Pathname(@target) + '19'
    
    job = staging.new_job @params
    assert_equal "20", Pathname.new(job.path).basename.to_s
  end
end
