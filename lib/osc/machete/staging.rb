require 'pathname'


module OSC
  module Machete
    class Staging
  
      #TODO: subclass to specify template location and destination directory?
      # 
      #    class HSPStaging < OSC::Appkit::Staging
      #      template "/path/to/template/dir"
      #      target "/path/to/target/dir"
      #      use_delimeters "@@", "@@"
      #    end
      # 
      # target could be a method name that returns the path
      # for example, in user's crimson files
      # 
      def initialize(template, target, script)
        # 
        # an OSC::Appkit::Location object...
        # or a URI helper? URI.copyTo(URI) or URI.copyTo(Pathname)
        # 
        @template = Pathname.new(template).cleanpath
        @target = Pathname.new(target).cleanpath
        @script = script # script name
    
        raise ArgumentError, 'target for staging should be a directory' unless @target.directory?
      end
  
      # create a new job by copying and rendering template
      # TODO: provide a dependency
      def new_job(params)
        jobdir = Location.new(@template).copy_to(new_jobdir)
        jobdir.render(params)
    
        Job.new(path: jobdir, script: @script)
      end
  
      def new_jobdir
        JobDir.new(@target).new_jobdir
      end
    end
  end
end