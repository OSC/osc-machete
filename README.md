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


Check the status of a job:

```ruby
s = OSC::Machete::Job.new(pbsid: "117711759.opt-batch.osc.edu").status
#=> #<OSC::Machete::Status:0x002ba824829e50 @char="R">
puts s #=> "Running"
```
* status returns an `OSC::Machete::Status` value object

Setup dependencies, submit, and delete a job:

```ruby
solve_job = OSC::Machete::Job.new(script: path_to_solve_script)
post_job = OSC::Machete::Job.new(script: path_to_post_script)

# ensure that post_job doesn't start till solve_job ends (with any exit status)
post_job.afterany(solve_job)

# submit both jobs (can do it in any order, dependencies will be managed for you)
post_job.submit
solve_job.submit

# if you want to qdel both jobs:
solve_job.delete
post_job.delete
```

* when submitting a job, if a shell script is not found, OSC::Machete::Job::ScriptMissingError error is raised
* `Job#submit`, `Job#status`, `Job#delete` all raise a `PBS::Error` if something
goes wrong with interacting with Torque.

#### Account String for submitting jobs

By default, the account string will be set as a command line argument to qsub
using the `-A` flag, which means setting this in a PBS header in the shell
scripts will not work. The default account_string is the primary group of the
process, which in our case happens to be the user.

If you need to change the default account_string, you can do so by providing an
extra argument to the OSC::Machete::Job initializer:

```ruby
j = OSC::Machete::Job.new(script: path_to_script)
j.account_string # nil - so when the job submits the primary group will be used

j = OSC::Machete::Job.new(script: path_to_script, account_string: "PZS0530")
j.account_string # "PZS0530" - so when the job submits "PZS0530" will be used
```

You can also set a class variable on the job object so that all future job
objects are instantiated using the specified account string:

```ruby
OSC::Machete::Job.default_account_string = "PZS0530"

j = OSC::Machete::Job.new(script: path_to_script)
j.account_string # "PZS0530" - so when the job submits "PZS0530" will be used
```

### OSC::Machete::Status

See [Martin Fowler on value objects](http://martinfowler.com/bliki/ValueObject.html)

```ruby
s = OSC::Machete::Job.new(pbsid: "117711759.opt-batch.osc.edu").status
#=> #<OSC::Machete::Status:0x002ba824829e50 @char="R">
puts s #=> "Running"

s.passed? #=> true
s.completed? #=> true
s.failed? #=> false
s.submitted? #=> true

f = OSC::Machete::Status.failed #=> #<OSC::Machete::Status:0x002ba8274334d8 @char="F">
f.failed? #=> true
f.completed? #=> true
```

To get an array of all the possible values:

```ruby
irb(main):001:0> OSC::Machete::Status.values
=> [#<OSC::Machete::Status:0x002ba201079918 @char="U">, #<OSC::Machete::Status:0x002ba2010798a0 @char=nil>, #<OSC::Machete::Status:0x002ba201079710 @char="C">, #<OSC::Machete::Status:0x002ba201079620 @char="F">, #<OSC::Machete::Status:0x002ba201079558 @char="H">, #<OSC::Machete::Status:0x002ba2010794e0 @char="Q">, #<OSC::Machete::Status:0x002ba2010793c8 @char="R">, #<OSC::Machete::Status:0x002ba201079328 @char="S">]
irb(main):002:0> OSC::Machete::Status.values.map(&:to_s)
=> ["Undetermined", "Not Submitted", "Passed", "Failed", "Held", "Queued", "Running", "Suspended"]
irb(main):003:0>
```

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
[24] pry(main)> puts OSC::Machete::Job.new(pbsid: "17711768.opt-batch.osc.edu").status
Running
=> nil
```

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
