module OSC
  module Machete
    module SimpleJob
      module Statusable
        # methods that deal with pbs batch job status management
        # within a Rails ActiveRecord model
        
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
        def job=(new_job)
          self.pbsid = new_job.pbsid
          self.job_path = new_job.path.to_s 
          self.script_name = new_job.script_name
          self.status = new_job.status
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
        
        # a hook that can be overid with custom code
        # also looks for default validation methods for existing 
        def results_valid?
          valid = true
          
          if self.respond_to? :script_name
            validation_method = File.basename(script_name, ".*").underscore.parameterize('_') + "_results_valid?"
            
            if self.respond_to?(validation_method)
              valid = self.send(validation_method)
            end
          end
          
          valid
        end
        
        #FIXME: should have a unit test for this!
        def update_status!
          if submitted? && ! completed?
            # if the status of the job is nil, the job is no longer in the batch
            # system, so it is either completed or failed
            current_status = OSC::Machete::Job.new(pbsid: pbsid).status
            if current_status == current_status.nil?
              current_status = results_valid? ? "C" : "F"
            end

            if current_status != self.status
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