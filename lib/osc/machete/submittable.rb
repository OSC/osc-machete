module OSC
  module Machete
    module SimpleJob
      module Submittable
        # methods that deal with pbs batch job staging and submission
        # within a Rails ActiveRecord model
        
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
end
