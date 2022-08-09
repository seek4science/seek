class Service < ApplicationRecord

  belongs_to :facility
  
  has_many :investigations, inverse_of: :service

  def self.can_create?(user = User.current_user)
    user&.is_admin?
  end

end
