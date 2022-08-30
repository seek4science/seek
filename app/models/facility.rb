class Facility < ApplicationRecord

  include Seek::Taggable
  
  validates :title, uniqueness: true

  has_and_belongs_to_many :institutions

  has_many :services, inverse_of: :facility

  auto_strip_attributes :web_page

  validates :web_page, url: { allow_nil: true, allow_blank: true }
  validates :country, country: true

  def self.can_create?(user = User.current_user)
    user&.is_admin?
  end

end
