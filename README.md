# OSC::Machete

Ruby code to help with staging and checking the status of batch jobs.


## Installation

To use 0.1.0, add this line to your application's Gemfile:

    gem 'osc-machete', :path => "/nfs/17/efranz/prod/osc-machete-0.1.0"

And then execute:

    $ bundle install --local

**This is a temporary solution. Once we figure out a workflow for installing new versions of the gem on the system, the way to add this to your application's Gemfile will change.**

## Usage


### OSC::Machete::Statusable

After including `OSC::Machete::Statusable` or `OSC::Machete::SimpleJob`, you will want to add the fields to the model for storing job data:

```
rails g migration add_job_attrs_to_simulation status:string pbsid:string job_path:string
rake db:migrate
```



### Example of using Machete directly via irb

```
-bash-3.2$ irb -I/nfs/17/efranz/prod/osc-machete-0.2.2/lib -rosc/machete
irb(main):009:0> j = OSC::Machete::Job.new pbsid: "2601223.oak-batch.osc.edu"
=> #<OSC::Machete::Job:0x002b861b94b340 @pbsid="2601223.oak-batch.osc.edu", @torque=#<OSC::Machete::TorqueHelper:0x002b861b94b318>>
irb(main):010:0> j.status
=> :R
```

Or you could write your own ruby script that  that does something using the gem:

```
-bash-3.2$ cat test.rb
require 'osc/machete'

pbsid = "2601268.oak-batch.osc.edu"
j = OSC::Machete::Job.new pbsid: pbsid
puts j.status
```

And then run it like this:

```
-bash-3.2$ ruby -I/nfs/17/efranz/prod/osc-machete-0.1.0/lib test.rb
Q
-bash-3.2$
```
