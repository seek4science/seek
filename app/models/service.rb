class Service < ApplicationRecord

  include Seek::Taggable
  
  belongs_to :facility
  has_many :institutions, through: :facility
  
  has_and_belongs_to_many :assays
  
  has_many :samples, through: :assays
  
  has_many :data_files, through: :assays
  
  def self.can_create?(user = User.current_user)
    user&.is_admin?
  end

end
