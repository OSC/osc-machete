
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
    end
  end
end
