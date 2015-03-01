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


### OSC::Machete::Statusable

After including `OSC::Machete::Statusable` or `OSC::Machete::SimpleJob`, you will want to add the fields to the model for storing job data:

```
rails g migration add_job_attrs_to_simulation status:string pbsid:string job_path:string script_name:string
rake db:migrate
```



### Example of using Machete directly via irb

```
-bash-3.2$ irb -rosc/machete
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
-bash-3.2$ ruby test.rb
Q
-bash-3.2$
```
