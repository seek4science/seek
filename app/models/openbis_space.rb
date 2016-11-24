# represents the details to connect to an openbis space
class OpenbisSpace < ActiveRecord::Base
  belongs_to :project

  validates :url, url: { allow_nil: true, allow_blank: true }
  validates :project, :url, :username, :password, :space_name, presence: true
end
