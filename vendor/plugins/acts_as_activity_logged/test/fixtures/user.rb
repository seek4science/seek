
class User < ActiveRecord::Base
  acts_as_activity_logged
end