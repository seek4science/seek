class Subscription < ActiveRecord::Base
  belongs_to :person
  belongs_to :project

  validates_presence_of :person
  validates_presence_of :project

  serialize :subscribed_resource_types

  # three subscription type
  NEVER = 0
  IMMEDIATELY = 1
  DAILY = 2
  WEEKLY = 3
  MONTHLY = 4

  def project_name
    project ? project.name : nil
  end

#  def subscribed_resource_types=  resource_type
#    unless subscribed_resource_types.nil?
#      subscribed_resource_types << resource_type
#    end
#  end



end