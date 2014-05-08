# declares the module
require "osc/machete/version"

# adds classes to the module
# FIXME: is this a bad practice? shoudl all these
# actually have
# module Machete
#   class Job
# in them?
# 
require "osc/machete/crimson"
require "osc/machete/job"
require "osc/machete/job_dir"
require "osc/machete/location"
require "osc/machete/torque_helper"
require "osc/machete/staging"
require "osc/machete/system"
require "osc/machete/user"

module OSC
  module Machete
    # Your code goes here...
  end
end
