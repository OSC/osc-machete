
# TODO: break into 2 files: simple_job_submit.rb and simple_job_status.rb
# both to populate SimpleJob module

module OSC
  module Machete
    # The SimpleJob module
    module SimpleJob

      # SimpleJob Initializer
      # 
      # Includes the Submittable and Statusable modules.
      # 
      # @param [Object] obj The base object.
      def self.included(obj)
        #HACK: we bypass the private visiblity of Module#include
        # for Ruby 2.0.0; in Ruby 2.1.0 Module#include is public
        # so this should be safe
        obj.send :include, OSC::Machete::SimpleJob::Submittable
        obj.send :include, OSC::Machete::SimpleJob::Statusable
      end
    end
  end
end
