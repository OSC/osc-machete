# Change Log

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]
### Added
- Status value object
- `User.from_uid` factory method
- `TorqueHelper#status_for_char` to determine what Status value to create based on Torque's symbol for the job's status.

### Changed
- `Job#status` now returns Status value


## [1.0.0.pre1] - 2015-12-18
### Added
- Process utility class
- Util methods `member_of_group?` and `groups` to User


### Changed
- Removed `OSC::Machete::SimpleJob` from gem
- User class now determines user using Etc module


## 0.6.3 - 2015-11-23

Previous release of osc-machete

[Unreleased]: https://github.com/AweSim-OSC/osc-machete/compare/v1.0.0.pre1...release/1.0
[1.0.0.pre1]: https://github.com/AweSim-OSC/osc-machete/compare/v0.6.3...v1.0.0.pre1

