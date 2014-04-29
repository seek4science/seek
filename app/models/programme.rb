class Programme < ActiveRecord::Base
  attr_accessible :avatar_id, :description, :first_letter, :title, :uuid, :web_page

  acts_as_favouritable
  acts_as_uniquely_identifiable

  #associations
  belongs_to :avatar

  #validations
  validates :title,:presence=>true
  validates :avatar,:associated=>true


end
