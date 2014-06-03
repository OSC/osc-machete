
# TODO: break into 2 files: simple_job_submit.rb and simple_job_status.rb
# both to populate SimpleJob module

module OSC
  module Machete
    module SimpleJob
      # expects class that includes it to have these methods
      # 
      # pbsid
      # status
      # save
      # job_path or script_path
      # 
      
      def self.included(obj)
        # TODO: throw warning if we detect that pbsid, status, save,
        # etc. are not apart of this; i.e.
        # Rails.logger.warn if Module.constants.include?(:Rails) && (! obj.respond_to?(:pbsid))
        # etc.
    
        # in Rails ActiveRecord objects after loaded from the database,
        # update the status
        if obj.respond_to?(:after_find)
          obj.after_find do |simple_job|
            simple_job.update_status!
          end
        end
      end
      
      def submitted?
        ! (pbsid.nil? || pbsid == "")
      end
  
      def completed?
        # FIXME: instead of storing magic constants
        # we need regular constants
        status == "C" || status == "F"
      end
  
      def failed?
        status == "F"
      end
  
      # returns true if in a running state (R,Q,H)
      def running?
        submitted? && ! completed?
      end
  
      # FIXME: better name for this?
      def status_human_readable
        statuses = {"H" => "Hold", "R" => "Running", "Q" => "Queued", "F" => "Failed", "C" => "Completed"}
        
        if ! submitted?
          "Not Submitted"
        else
          # FIXME: is this safe? perhaps a default?
          statuses[status]
        end
      end
  
      #FIXME: should have a unit test for this!
      def update_status!
        if submitted? && ! completed?
          # if the status of the job is nil, the job is no longer in the batch
          # system, so it is either completed or failed
          current_status = OSC::Machete::Job.new(pbsid: pbsid).status
          current_status = current_status.nil? ? "C" : current_status.to_s
      
          if current_status != self.status
            # FIXME: how do we integrate logging into Rails apps?
            # puts "status changed. current_status: #{current_status} and status is #{status}"
            self.status = current_status
            self.save
          end
        end
      end
      

      # job submission methods
      
      # 
      # hook methods are rails-specific i.e. they require
      # ActiveSupport or expect Rails.application to be defined
      # 
      
      # template directory location
      def staging_template_name
        # Simulation => simulation
        # FlowratePerfRun => flowrate_perf_run
        # etc.
        self.class.name.underscore
      end

      def staging_script_name
        "main.sh"
      end

      def crimson_files_dir_name
        # TODO: maybe it should be a constant that is auto-set to Rails.application.class.parent_name
        # such as CRIMSON_FILES_DIR_NAME=Rails.application.class.parent_name
        # in an initializer
        # in this case it ends up being "HelloSim"
        Rails.application.class.parent_name
      end

      def staging_target_dir_name
        # FIXME: is there any reason to pluralize?
        # removing this constraint could offer more options for naming things

        # Simulation => simulations
        # FlowratePerformanceRun => flowrate_performance_runs
        self.class.name.underscore.pluralize
      end

      def staging_target_dir
        # TODO: add jobs to ~/crimson_files/DemoSim/jobs/
        # and file uploads to another location later (perhaps ~/crimson_files/DemoSim/files/)
        # or perhaps different types of jobs in different dirs i.e.
        # ~/crimson_files/DemoSim/flowrate_performance_tests/

        OSC::Machete::Crimson.new(crimson_files_dir_name).files_path.join(staging_target_dir_name)
      end
      
      
      # build staging class
      # uses hook methods to get specific arguments
      # such as the template name, etc.
      def staging
        template = Rails.root.join("jobs", staging_template_name)
        target = staging_target_dir

        # some exception goes here when the template directory doesn't exist
        raise "You are trying to submit a job with a template directory #{template.to_s} 
               but it does not exist or is not a directory!" unless template.directory?

        # if target directory (where job instances are created) doesn't exist, create it
        FileUtils.mkdir_p target

        # return staging object
        OSC::Machete::Staging.new template, target, staging_script_name
      end

      def submit(params)
        # stage and submit job
        job = staging.new_job params
        job.submit

        # persist job data
        self.status = job.status
        self.pbsid = job.pbsid
        self.job_path = job.path.to_s
        self.save
      end
      
    end
  end
end
