# represents the details to connect to an openbis space
class OpenbisSpace < ActiveRecord::Base
  belongs_to :project

  validates :as_endpoint, url: { allow_nil: true, allow_blank: true }
  validates :dss_endpoint, url: { allow_nil: true, allow_blank: true }
  validates :project, :as_endpoint, :dss_endpoint, :username, :password, :space_name, presence: true

  def self.can_create?
    User.logged_in_and_member? && User.current_user.is_admin_or_project_administrator? && Seek::Config.openbis_enabled
  end

  def can_edit?(user=User.current_user)
    user && project.can_be_administered_by?(user) && Seek::Config.openbis_enabled
  end

  def test_authentication
    begin
      str=Fairdom::OpenbisApi::Authentication.new(username, password, url).login['token']
      puts str.inspect
      !str.nil?
    rescue Fairdom::OpenbisApi::OpenbisQueryException=>e
      false
    end
  end

end
