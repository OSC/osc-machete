require 'pathname'


module OSC
  module Machete
    # Class for managing template locations and paths.
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
      # @param [String] template The path to the job template.
      # @param [String] target The path to the job target.
      # @param [String, nil] script The script file name (Default: 'main.sh')
      def initialize(template, target, script="main.sh")
        #
        # an OSC::Appkit::Location object...
        # or a URI helper? URI.copyTo(URI) or URI.copyTo(Pathname)
        #
        @template = Pathname.new(template).cleanpath
        @target = Pathname.new(target).cleanpath
        @script = script # script name

        raise ArgumentError, 'target for staging should be a directory' unless @target.directory?
      end

      # copy directory to new job directory and render mustache template files
      # return created directory
      def stage(params)
        jobdir = Location.new(@template).copy_to(new_jobdir)
        jobdir.render(params)
        jobdir.to_s
      end

      # <b>DEPRECATED:</b> use <tt>stage</tt> and create Job objects outside of this class
      # The staging class should not be concerned with creating Job objects.
      #
      # create a new job by copying and rendering template
      # TODO: provide a dependency
      def new_job(params)
        Job.new(script: Pathname.new(stage(params)).join(@script))
      end

      # Creates a new JobDir object and path.
      #
      # @return [JobDir] A JobDir object initialized to @target and assigned a unique folder.
      def new_jobdir
        JobDir.new(@target).new_jobdir
      end
    end
  end
end
