class Facility < ApplicationRecord

  has_and_belongs_to_many :institutions

  has_many :services, inverse_of: :facility

  def self.can_create?(user = User.current_user)
    user&.is_admin?
  end

end
