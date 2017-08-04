require 'minitest/autorun'
require 'osc/machete'
require 'pbs'
require 'mocha/setup'

# test helper class
class TestTorqueHelper < Minitest::Test

  # FIXME:
  # will be replacing with programmatic access to torque
  # however... we should have our tests actually submit tiny jobs on a queue that can respond immediately,
  # run for a minute, and die
  # perhaps using the Oxymoron cluster for this purpose?
  #
  # 2016/01/08  Implemented this in `test_qsub_oakley` and `test_qsub_ruby`. The test only runs when rake
  #             is called on the correct submit host. On all other systems, only the stubs are used.

  def setup
    # FIXME: Torque only works from websvsc02
    #   This raises an issue mentioning that it is not being submitted on the
    #   correct host, comment out the raise to skip the live tests.
    #   Maybe this would be better accomplished with a separate rake task.
    @submit_host = "websvcs02.osc.edu"

    @job_state_queued = OSC::Machete::Status.queued
    @job_state_completed = OSC::Machete::Status.passed
    @job_state_running = OSC::Machete::Status.running
    @job_state_undetermined = OSC::Machete::Status.undetermined

    @shell = OSC::Machete::TorqueHelper.new

    # test staging using HSP template
    #@params = YAML.load(File.read('test/fixtures/app-params.yml'))
    #@template = 'test/fixtures/app-template'
    #@expected = 'test/fixtures/app-template-rendered'

    # directory where to create jobs
    #@target = Dir.mktmpdir
    #@script = 'GLO_job'

    @script_oakley = 'test/fixtures/oakley.sh'
    @script_ruby = 'test/fixtures/ruby.sh'
  end

  # FIXME: what is the purpose of these tests?
  # # Test qstat parameters for completed job.
  # def test_qsub_oakley_stub
  #   PBS::Job.any_instance.stubs(:submit).with(file: @script_oakley, headers: {}, qsub: true).returns(PBS::Job.new(conn: 'oakley', id: '1234598.oak-batch.osc.edu'))
  #   assert_equal "1234598.oak-batch.osc.edu", @shell.qsub(@script_oakley)
  #   PBS::Job.any_instance.unstub(:submit)
  # end

  # # Test job state parser when returning queued
  # def test_qsub_ruby_stub
  #   PBS::Job.any_instance.stubs(:submit).with(file: @script_ruby, headers: {}, qsub: true).returns(PBS::Job.new(conn: 'ruby', id: '1234598'))
  #   assert_equal "1234598", @shell.qsub(@script_ruby)
  #   PBS::Job.any_instance.unstub(:submit)
  # end
  
  def test_qstat_state_no_job
    PBS::Batch.any_instance.stubs(:get_job).raises(PBS::UnkjobidError, "Unknown Job Id")
    assert_equal @job_state_completed, @shell.qstat("")
    assert_equal @job_state_completed, @shell.qstat(nil)
    PBS::Batch.any_instance.unstub(:get_job)
  end

  # Test that qstat returns Running job StatusValue
  def test_qstat_state_running_oakley
    PBS::Batch.any_instance.stubs(:get_job).returns({ "123.oak-batch.osc.edu" => { :job_state => "R" }})
    assert_equal @job_state_running, @shell.qstat("123.oak-batch.osc.edu")
    PBS::Batch.any_instance.unstub(:get_job)
  end

  # Test that qstat returns Queued job StatusValue
  def test_qstat_state_queued_oakley
    PBS::Batch.any_instance.stubs(:get_job).returns({ "123.oak-batch.osc.edu" => { :job_state => "Q" }})
    assert_equal @job_state_queued, @shell.qstat("123.oak-batch.osc.edu")
    PBS::Batch.any_instance.unstub(:get_job)
  end

  # Test that qstat returns Queued job StatusValue
  def test_qstat_state_running_ruby
    PBS::Batch.any_instance.stubs(:get_job).returns({ "12398765" => { :job_state => "Q" }})
    assert_equal @job_state_queued, @shell.qstat("12398765")
    PBS::Batch.any_instance.unstub(:get_job)
  end

  # Test that qstat returns Completed job StatusValue when state is nil.
  def test_qstat_state_completed_oakley
    PBS::Batch.any_instance.stubs(:get_job).raises(PBS::UnkjobidError, "Unknown Job Id Error")
    assert_equal @job_state_completed, @shell.qstat("123.oak-batch.osc.edu")
    PBS::Batch.any_instance.unstub(:get_job)

    PBS::Batch.any_instance.stubs(:get_job).raises(PBS::UnkjobidError, "Unknown Job Id")
    assert_equal @job_state_completed, @shell.qstat("123.oak-batch.osc.edu")
    PBS::Batch.any_instance.unstub(:get_job)
  end

  # Test that qdel works for oakley
  def test_qdel_oakley_ok
    PBS::Batch.any_instance.stubs(:delete_job).returns(true)
    assert_equal true, @shell.qdel("123.oak-batch.osc.edu")
    PBS::Batch.any_instance.unstub(:delete_job)
  end

  # Test that qdel works for quick batch
  def test_qdel_quick
    PBS::Batch.any_instance.stubs(:delete_job).returns(true)
    assert_equal true, @shell.qdel("123.quick-batch.ten.osc.edu")
    PBS::Batch.any_instance.unstub(:delete_job)
  end

  # Test that qdel works for Ruby cluster
  def test_qdel_ruby
    PBS::Batch.any_instance.stubs(:delete_job).returns(true)
    assert_equal true, @shell.qdel("12365478")
    PBS::Batch.any_instance.unstub(:delete_job)
  end

  # Test that qdel throws exception on PBS exception
  def test_qdel_throws_exception
    PBS::Batch.any_instance.stubs(:delete_job).raises(PBS::Error)
    assert_raises(PBS::Error) { @shell.qdel("123.quick-batch.ten.osc.edu") }
    PBS::Batch.any_instance.unstub(:delete_job)

    PBS::Batch.any_instance.stubs(:delete_job).raises(PBS::SystemError)
    assert_raises(PBS::SystemError) { @shell.qdel("123.quick-batch.ten.osc.edu") }
    PBS::Batch.any_instance.unstub(:delete_job)
  end

  # Test that qdel doesn't throw exception if Unknown Job Id exception
  def test_qdel_doesnt_throw_exception_on_unknown_job_id
    PBS::Batch.any_instance.stubs(:delete_job).raises(PBS::UnkjobidError)
    @shell.qdel("123.quick-batch.ten.osc.edu")
    PBS::Batch.any_instance.unstub(:delete_job)
  end
  
  def assert_qsub_dependency_list(dependency_list, dependencies, host=nil)
    assert_equal dependency_list, @shell.qsub_dependencies_header(dependencies)
  end
  
  def test_qsub_afterany
    assert_qsub_dependency_list("afterany:1234.oak-batch.osc.edu", { afterany: ["1234.oak-batch.osc.edu"] })
    assert_qsub_dependency_list("afterany:1234.oakbatch.osc.edu", { afterany: "1234.oakbatch.osc.edu" })
    assert_qsub_dependency_list("afterany:1234.oakbatch.osc.edu:2345.oakbatch.osc.edu", { afterany: ["1234.oakbatch.osc.edu", "2345.oakbatch.osc.edu"] })
    return true
  end
  

  def test_qsub_afterok
    assert_qsub_dependency_list("afterok:1234.oakbatch.osc.edu", { afterok: ["1234.oakbatch.osc.edu"] })
    assert_qsub_dependency_list("afterok:1234.oakbatch.osc.edu:2345.oakbatch.osc.edu", { afterok: ["1234.oakbatch.osc.edu", "2345.oakbatch.osc.edu"] })
    return true
  end
  
  # With multiple dependency types, is formatted:
  #   type[:argument[:argument...][,type:argument...]
  # i.e. 
  #   -W depend=afterany:1234.oakbatch.osc.edu,afterok:2345.oakbatch.osc.edu"
  # 
  # See qsub manpage for details
  def test_qsub_afterok_and_afterany
    assert_qsub_dependency_list("afterany:1234.oakbatch.osc.edu,afterok:2345.oakbatch.osc.edu", { afterany: "1234.oakbatch.osc.edu", afterok: "2345.oakbatch.osc.edu" } )
    return true
  end
  
  def test_qsub_other
    assert_qsub_dependency_list("after:1234.oakbatch.osc.edu", { after: ["1234.oakbatch.osc.edu"] })
    assert_qsub_dependency_list("afternotok:1234.oakbatch.osc.edu:2345.oakbatch.osc.edu", { afternotok: ["1234.oakbatch.osc.edu", "2345.oakbatch.osc.edu"] })
    return true
  end
  
  def test_qsub_all_dependencies
    dependencies = {
      afterany: "1234.oakbatch.osc.edu",
      afterok: "2345.oakbatch.osc.edu",
      after: ["2347.oakbatch.osc.edu", "2348.oakbatch.osc.edu"],
      afternotok: ["2349.oakbatch.osc.edu", "2350.oakbatch.osc.edu", "2351.oakbatch.osc.edu"]
    }
    
    depencencies_str = "afterany:1234.oakbatch.osc.edu"
    depencencies_str += ",afterok:2345.oakbatch.osc.edu"
    depencencies_str += ",after:2347.oakbatch.osc.edu:2348.oakbatch.osc.edu"
    depencencies_str += ",afternotok:2349.oakbatch.osc.edu:2350.oakbatch.osc.edu:2351.oakbatch.osc.edu"
    
    assert_qsub_dependency_list(depencencies_str, dependencies)
    return true
  end

  def test_account_string_passed_into_qsub_used_during_submit_call
    PBS::Batch.any_instance.expects(:submit_script).with(@script_oakley, has_entry(headers: {Account_Name: "XXX"})).returns('1234598.oak-batch.osc.edu')
    @shell.qsub(@script_oakley, account_string: "XXX")
    PBS::Batch.any_instance.unstub(:submit_script)
  end

  def test_default_account_string_used_in_qsub_during_submit_call
    @shell.stubs(:default_account_string).returns("PZS3000")

    PBS::Batch.any_instance.expects(:submit_script).with(@script_oakley, has_entry(headers: {Account_Name: @shell.default_account_string})).returns('1234598.oak-batch.osc.edu')
    @shell.qsub(@script_oakley)

    @shell.stubs(:default_account_string).returns("appl")
    PBS::Batch.any_instance.expects(:submit_script).with(@script_oakley, has_entry(headers: {})).returns('1234598.oak-batch.osc.edu')
    @shell.qsub(@script_oakley)

    PBS::Batch.any_instance.unstub(:submit_script)
    @shell.unstub(:default_account_string)
  end

  def test_pbs_default_host
    s = @shell.pbs
    assert_equal 'oak-batch.osc.edu', s.host
    assert_equal OSC::Machete::TorqueHelper::LIB, s.lib.to_s
    assert_equal OSC::Machete::TorqueHelper::BIN, s.bin.to_s
  end

  def test_pbs_host_variations
    # you can use the cluster ids
    assert_equal 'ruby-batch.ten.osc.edu', @shell.pbs(host: 'ruby').host

    # or you can use the host itself
    assert_equal 'ruby-batch.osc.edu', @shell.pbs(host: 'ruby-batch.osc.edu').host
    assert_equal '@ruby-batch', @shell.pbs(host: '@ruby-batch').host

    assert_equal 'ruby-batch.ten.osc.edu', @shell.pbs(id: '4567').host
    assert_equal 'ruby-batch.ten.osc.edu', @shell.pbs(script: @script_ruby).host
    assert_equal 'oak-batch.osc.edu', @shell.pbs(script: @script_oakley).host
  end

  def test_setting_default_torque_helper
    d = OSC::Machete::TorqueHelper.default

    assert_equal 'oak-batch.osc.edu', OSC::Machete::TorqueHelper.default.pbs.host

    # this is an example of how you can quickly modify the default behavior of
    # a TorqueHelper instance to provide a new host, id, and script
    d2 = OSC::Machete::TorqueHelper.new
    class << d2
      def pbs(host: nil, id: nil, script: nil)
        PBS::Batch.new(
          host: "ruby-batch.osc.edu",
          lib: LIB,
          bin: BIN
        )
      end
    end

    OSC::Machete::TorqueHelper.default = d2

    assert_equal 'ruby-batch.osc.edu', OSC::Machete::TorqueHelper.default.pbs.host

    OSC::Machete::TorqueHelper.default = d
  end
end
