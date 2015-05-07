module OSC
  module Machete
    module SimpleJob
      module Workflow

        def has_machete_workflow_of(jobs_active_record_relation_symbol)
          # yes, this is magic mimicked from http://guides.rubyonrails.org/plugins.html
          #  and http://yehudakatz.com/2009/11/12/better-ruby-idioms/
          cattr_accessor :jobs_active_record_relation_symbol
          self.jobs_active_record_relation_symbol = jobs_active_record_relation_symbol

          # separate modules to group common methods for readability purposes
          # both builder methods and status methods need the jobs relation so
          # we include that first
          self.send :include, OSC::Machete::SimpleJob::Workflow::JobsRelation
          self.send :include, OSC::Machete::SimpleJob::Workflow::BuilderMethods
          self.send :include, OSC::Machete::SimpleJob::Workflow::StatusMethods
        end

        module JobsRelation
          def jobs_active_record_relation
            self.send self.class.jobs_active_record_relation_symbol
          end
        end

        # depends on jobs_active_record_relation being defined
        module BuilderMethods
          #FIXME: this should be a constant provided by the app: data_root
          def data_root
            raise NotImplementedError, "Objects including "\
              "OSC::Machete::SimpleJob::Workflow must implement data_root "\
              "OR include awesim_rails gem in project" unless defined? AwesimRails
            AwesimRails.dataroot.join(staging_target_dir_name)
          end

          def staging_template_name
            self.class.name.underscore
          end

          # Simulation => simulations
          # FlowratePerformanceRun => flowrate_performance_runs
          def staging_target_dir_name
            staging_template_name.pluralize
          end

          def staging_target_dir
            data_root.join(staging_target_dir_name)
          end

          def stage
            staging_template_dir = Rails.root.join("jobs", staging_template_name)

            staged_dir = OSC::Machete::JobDir.new(staging_target_dir).new_jobdir
            FileUtils.mkdir_p staged_dir
            FileUtils.cp_r staging_template_dir.to_s + "/.", staged_dir

            staged_dir
          end

          def render_mustache_files(staged_dir, template_view)
            Location.new(staged_dir).render(template_view)
          end

          def after_stage(staged_dir)
          end

          # returns an array of unsubmitted OSC::Machete::Job objects with their dependencies (if any) configured
          def build_jobs(staged_dir, jobs = [])
            raise NotImplementedError, "Objects including OSC::Machete::SimpleJob::Workflow must implement build_jobs"
          end

          def submit_jobs(jobs)
            jobs.each(&:submit)
          end

          def save_jobs(jobs, staged_dir)
            self.staged_dir = staged_dir.to_s if self.respond_to?(:staged_dir=)
            self.save if self.id.nil? || self.respond_to?(:staged_dir=)

            jobs.each do |job|
              self.jobs_active_record_relation.create(job: job)
            end
          end

          # do everything
          def submit(template_view=self)
            staged_dir = stage
            render_mustache_files(staged_dir, template_view)
            after_stage(staged_dir)
            jobs = build_jobs(staged_dir)
            submit_jobs(jobs)
            save_jobs(jobs, staged_dir)
          end
        end

        # depends on jobs_active_record_relation being defined
        module StatusMethods
          extend Gem::Deprecate
          
          def submitted?
            jobs_active_record_relation.count > 0
          end

          def completed?
            # true if all jobs are completed
            submitted? && jobs_active_record_relation.where(status: ["F", "C"]).count == jobs_active_record_relation.count
          end

          def failed?
            # true if any of the jobs .failed?
            jobs_active_record_relation.where(status: ["F"]).any?
          end

          # returns true if in a running state (R,Q,H) i.e. not completed and not submitted
          def running_queued_or_hold?
            active?
          end
          deprecate :running_queued_or_hold?, "Use active? instead", 2015, 03
          
          def active?
            submitted? && ! completed?
          end

          # FIXME: better name for this?
          def status_human_readable
            if failed?
              "Failed"
            elsif completed?
              "Completed"
            elsif jobs_active_record_relation.where(status: "R").any?
              "Running"
            elsif jobs_active_record_relation.where(status: "Q").any?
              "Queued"
            elsif jobs_active_record_relation.where(status: "H").any?
              "Hold"
            else
              "Not Submitted"
            end
          end
        end

        # extend Active Record with the has_workflow_of method
        ActiveRecord::Base.extend OSC::Machete::SimpleJob::Workflow if defined? ActiveRecord::Base
      end
    end
  end
end

