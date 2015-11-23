module OSC
  module Machete
    module SimpleJob
      # Methods that deal with pbs batch job status management
      # within a Rails ActiveRecord model
      module Statusable
        extend Gem::Deprecate

        # Initialize the object
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

        # Setter that accepts an OSC::Machete::Job instance
        #
        # @param [Job] new_job The Job object to be assigned to the Statusable instance.
        def job=(new_job)
          self.pbsid = new_job.pbsid
          self.job_path = new_job.path.to_s
          self.script_name = new_job.script_name if respond_to?(:script_name=)
          self.status = new_job.status
        end

        # Returns associated OSC::Machete::Job instance
        def job
          script_path = respond_to?(:script_name) ? Pathname.new(job_path).join(script_name) : nil
          OSC::Machete::Job.new(pbsid: pbsid, script: script_path)
        end

        # Returns true if the job has been submitted.
        #
        # If the pbsid is nil or the pbsid is an empty string,
        # then the job hasn't been submitted and method returns false.
        #
        # @return [Boolean] true if the job has been submitted.
        def submitted?
          ! (pbsid.nil? || pbsid == "")
        end

        # Returns true if the job is no longer running.
        #
        # If the job status is completed or failed
        # return true.
        #
        # @return [Boolean] true if job is no longer running.
        def completed?
          status.to_s == "C" || status.to_s == "F"
        end

        # Returns true if the job has failed.
        #
        # @return [Boolean] true if the job has failed.
        def failed?
          status.to_s == "F"
        end

        # Returns true if in a running state (R,Q,H)
        #
        # DEPRECATED: Use 'active?' instead.
        #
        # @return [Boolean] true if in a running state.
        def running?
          active?
        end
        deprecate :running?, "Use active? instead", 2015, 03

        # Returns true if in a running state (R,Q,H)
        #
        # @return [Boolean] true if in a running state.
        def running_queued_or_hold?
          active?
        end
        deprecate :running_queued_or_hold?, "Use active? instead", 2015, 03

        # Returns true if the job has been submitted and is not completed.
        #
        # @return [Boolean] true if the job has been submitted and is not completed.
        def active?
          submitted? && ! completed?
        end

        # Returns a string representing a human readable status label.
        #
        # Status options:
        #   Hold
        #   Running
        #   Queued
        #   Failed
        #   Completed
        #   Not Submitted
        #
        # @return [String] A String representing a human readable status label.
        def status_human_readable
          statuses = {"H" => "Hold", "R" => "Running", "Q" => "Queued", "F" => "Failed", "C" => "Completed"}

          if ! submitted?
            "Not Submitted"
          else
            # FIXME: is this safe? perhaps a default?
            statuses[status.to_s]
          end
        end

        # Build the results validation method name from script_name attr
        # using ActiveSupport methods
        #
        # Call this using the Rails console to see what method you should implement
        # to support results validation for that job.
        #
        # @return [String] A string representing a validation method name from script_name attr
        # using ActiveSupport methods
        def results_validation_method_name
          File.basename(script_name, ".*").underscore.parameterize('_') + "_results_valid?"
        end

        # A hook that can be overidden with custom code
        # also looks for default validation methods for existing
        # WARNING: THIS USES ActiveSupport::Inflector methods underscore and parameterize
        #
        # @return [Boolean] true if the results script is present
        def results_valid?
          valid = true

          if self.respond_to? :script_name
            if self.respond_to?(results_validation_method_name)
              valid = self.send(results_validation_method_name)
            end
          end

          valid
        end

        #FIXME: should have a unit test for this!
        # job.update_status! will update and save object
        # if submitted? and ! completed? and status changed from previous state
        # force will cause status to update regardless of completion status,
        # redoing the validations. This way, if you are fixing validation methods
        # you can use the Rails console to update the status of a Workflow by doing this:
        #
        #     Container.last.jobs.each {|j| j.update_status!(force: true) }
        #
        # Or for a single statusable such as job:
        #
        #     job.update_status!(force: true)
        #
        # FIXME: should log whether a validation method was called or
        # throw a warning that no validation method was found (the one that would have been called)
        #
        # @param [Boolean, nil] force Force the update. (Default: false)
        def update_status!(force: false)
          if submitted? && (! completed? || force)
            # if the status of the job is nil, the job is no longer in the batch
            # system, so it is either completed or failed
            current_status = job.status
            if current_status.nil? || current_status.to_s == "C"
              current_status = results_valid? ? "C" : "F"
            end

            if current_status.to_s != self.status.to_s || force
              # FIXME: how do we integrate logging into Rails apps?
              # puts "status changed. current_status: #{current_status} and status is #{status}"
              self.status = current_status
              self.save
            end
          end
        end
      end
    end
  end
end
