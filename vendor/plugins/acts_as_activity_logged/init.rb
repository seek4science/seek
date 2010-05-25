require 'activity_log'
require 'acts_as_activity_logged'

ActiveRecord::Base.send :include, NewBamboo::Acts::ActivityLogged