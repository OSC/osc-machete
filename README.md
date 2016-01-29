# OSC::Machete

Ruby code to help with staging and checking the status of batch jobs.


## Installation

To use, add this line to your application's Gemfile:

    gem 'osc-machete'

And then execute:

    $ bundle install --local


If you don't have osc-machete installed, you can do so by:

1. clone this repo
2. checkout the tag you want to build
3. `rake install`

Alternatively, you can use the latest version of the repo via bundler's git option:

    gem 'osc-machete', :git => 'git@github.com:AweSim-OSC/osc-machete.git'

## Usage

Three main classes are provided: Job, Process, and User.
The other are support classes for these three.


### OSC::Machete::Job

This is the main class and is a utility class for managing batch simulations. It
uses pbs-ruby to submit jobs, check the status of jobs, and stop running jobs.

**TODO PRY EXAMPLES**

### OSC::Machete::Process

Gives information about the running process. Uses Ruby's Process library when it
makes sense.

Examles using pry:

```
[14] pry(main)> OSC::Machete::Process.new.groupname
=> "PZS0562"
[15] pry(main)> OSC::Machete::Process.new.username
=> "efranz"
[16] pry(main)> OSC::Machete::Process.new.home
=> "/nfs/17/efranz"
[17] pry(main)> OSC::Machete::Process.new.group_membership_changed?
=> false
```

### OSC::Machete::User

Gives informaiton about the specified user, by using Ruby's Etc library and
inspecting the group membership file.

Example using pry:

```
[18] pry(main)> OSC::Machete::User.new.member_of_group?("awsmdev")
=> true
[19] pry(main)> OSC::Machete::User.new.home
=> "/nfs/17/efranz"
[20] pry(main)> OSC::Machete::Process.new.home
=> "/nfs/17/efranz"
[21] pry(main)> OSC::Machete::User.new.groups
=> [2959,
 3140,
 3141,
 3179,
 3285,
 3528,
 3572,
 4391,
 4497,
 4498,
 4511,
 4514,
 4517,
 4580,
 4807,
 4808]
```

### Example of using Machete directly via irb

```sh
-bash-3.2$ pry -rosc/machete
[24] pry(main)> OSC::Machete::Job.new(pbsid:
"17711768.opt-batch.osc.edu").status
=> Running
```

**TODO: redo after updating to_char, to_s, and inspect**

Or you could write your own ruby script that  that does something using the gem:

```sh
-bash-3.2$ cat test.rb
require 'osc/machete'

pbsid = "17711768.opt-batch.osc.edu"
j = OSC::Machete::Job.new pbsid: pbsid
puts j.status
```

And then run it like this:

```sh
-bash-3.2$ ruby test.rb
Running
-bash-3.2$
```
