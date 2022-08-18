class Service < ApplicationRecord

  belongs_to :facility
  
  has_and_belongs_to_many :assays
  
  def self.can_create?(user = User.current_user)
    user&.is_admin?
  end

end
