# Change Log

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

## [1.1.1] - 2016-02-24

### Fixed

- Omit account string when submitting a job if using default account string that is an invalid project i.e. `appl`

## [1.1.0] - 2016-02-18

### Changed

- Account string by default is specified as being the primary group name of the
process running the app. This corresponds to OSC's convention that the primary
group is the project of the user.
- OSC::Machete::Job is updated to change the default account string used for all
instances via setting OSC::Machete::Job.default_account_string
- OSC::Machete::Job is updated to accept account_string as an argument to the
initializer to use for that instance.

## [1.0.1] - 2016-02-16

### Fixed

- use latest version of pbs gem and its custom Error classes to catch the common cases for qdel and qstat when the pbsid is unknown

## [1.0.0] - 2016-02-03

### Fixed

- qstat would return nil if the job completed or if an error occurred with qstat; now qstat throws exception in error cases and returns a valid Status value otherwise
- using qstat with a Ruby job would fail because Ruby pbsid's don't include the host; fixed by adding host arg and if thats omitted inspecting the script first or else assuming its Ruby if the host is omitted from the job id

### Added

- lib/osc/machete/status.rb: Status value object
- lib/osc/machete/process.rb: Provides helper methods wrapping Etc and Process modules to inspect user info from the currently running process.



### Changed

lib/osc/machete/user.rb

- uses Etc instead of the environment variables to determine the current user by default (but any username can be passed in)
- provides information about the specified user from Etc and inspecting the system's groups file
- new methods include User#groups, User#member_of_group?, and a factory method to get an instance from the uid: User.from_uid

lib/osc/machete/job.rb

- host can be past in as an argument to the initializer; if this is not provided, torque_helper internally will try to determine what OSC system the PBSID corresponds to, or try inspecting the script for PBS headers
- Job#submit now throws ScriptMissingError or PBS::Error
- Job#status now returns an OSC::Machete::Status object instead of a character
- Job#delete now throws PBS::Error

lib/osc/machete/torque_helper.rb _(still an internal class right now, not meant to be used directly)_

- try to determine what OSC system the PBSID corresponds to, or try inspecting the script for PBS headers
- returns OSC::Machete::Status for qsub, qstat, qdel
- uses pbs gem instead of shelling out for qsub, qstat, qdel
- throws PBS::Error for qsub, qstat, qdel in erroneous cases
- handles mapping between Torque specific status values and the generic OSC::Machete::Status
- if host not provided, tries to determine host from pbsid and job script

### Removed

- lib/osc/machete/simple_job.rb - module is now alias for OscMacheteRails in the os_machete_rails gem; but including SimpleJob no longer results in including Statutable and Submittable
- lib/osc/machete/simple_job/statusable.rb - moved to osc_machete_rails
- lib/osc/machete/simple_job/workflow.rb - moved to osc_machete_rails
- lib/osc/machete/simple_job/submittable.rb - removed! use has_workflow_of instead
- lib/osc/machete/staging.rb - removed!

## 0.6.3 - 2015-11-23

Previous release of osc-machete

[Unreleased]: https://github.com/AweSim-OSC/osc-machete/compare/v1.1.1...master
[1.1.1]: https://github.com/AweSim-OSC/osc-machete/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/AweSim-OSC/osc-machete/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/AweSim-OSC/osc-machete/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/AweSim-OSC/osc-machete/compare/v0.6.3...v1.0.0

