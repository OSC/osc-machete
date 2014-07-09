
# TODO: break into 2 files: simple_job_submit.rb and simple_job_status.rb
# both to populate SimpleJob module

module OSC
  module Machete
    module SimpleJob
      def self.included(obj)
        obj.include OSC::Machete::SimpleJob::Submittable
        obj.include OSC::Machete::SimpleJob::Statusable
      end
    end
  end
end
