module OSC
  module Machete
    module SimpleJob
      # Methods that deal with pbs batch job staging and submission
      # within a Rails ActiveRecord model
      #
      # Hook methods are rails-specific i.e. they require
      # ActiveSupport or expect Rails.application to be defined
      module Submittable

        # Staging template directory location with underscores based on the calling class name.
        #
        # @example Simulation => simulation
        # @example FlowratePerfRun => flowrate_perf_run
        #
        # @return [String] The staging template directory location.
        def staging_template_name
          # Simulation => simulation
          # FlowratePerfRun => flowrate_perf_run
          # etc.
          self.class.name.underscore
        end

        # Returns the staging script name.
        #
        # Currently static "main.sh"
        #
        # @return [String] The staging script name: "main.sh"
        def staging_script_name
          "main.sh"
        end

        # Returns a name of the staging target that has been underscored and pluralized
        # based on the class name.
        #
        # @example Simulation => simulations
        # @example FlowratePerformanceRun => flowrate_performance_runs
        #
        # @return [String] The staging target directory name that has been underscored and pluralized.
        def staging_target_dir_name
          self.class.name.underscore.pluralize
        end

        # Returns the full path of the staging target directory combined with the rails dataroot.
        #
        # @return [String] The path of the staging target directory combined with the rails dataroot.
        def staging_target_dir
          raise "override staging_target_dir or include awesim_rails gem" unless defined? AwesimRails
          AwesimRails.dataroot.join(staging_target_dir_name)
        end

        # Build staging class
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

        # Submits the job and saves to the database.
        #
        # @param [Object, nil] template_view A template view object or the template view staged to the job.
        def submit(template_view=self)
          # FIXME: uncomment to replace `job = staging.new_job params` when
          # you bump to an incompatible version if you keep SimpleJob::Submittable
          #
          # # stage
          # staged_dir = staging.stage(params)
          #
          # # create and submit job
          # job = Job.new(script: Pathname.new(staged_dir).join(@script))
          job = staging.new_job template_view
          job.submit

          # persist job data (use job= specified on statusable)
          self.job = job
          self.save
        end
      end
    end
  end
end
