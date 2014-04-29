class Programme < ActiveRecord::Base
  attr_accessible :avatar_id, :description, :first_letter, :title, :uuid, :web_page

  acts_as_favouritable
  acts_as_uniquely_identifiable

  #associations
  belongs_to :avatar
  has_many :projects

  #validations
  validates :title,:presence=>true
  validates :avatar,:associated=>true

  def people
    projects.collect{|p| p.people}.flatten.uniq
  end

  def institutions
    projects.collect{|p| p.institutions}.flatten.uniq
  end


end
