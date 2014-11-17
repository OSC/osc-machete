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

