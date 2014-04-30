class Programme < ActiveRecord::Base
  attr_accessible :avatar_id, :description, :first_letter, :title, :uuid, :web_page

  acts_as_yellow_pages

  #associations
  has_many :projects

  #validations
  validates :title,:uniqueness=>true

  scope :default_order, order('title')

  def people
    projects.collect{|p| p.people}.flatten.uniq
  end

  def institutions
    projects.collect{|p| p.institutions}.flatten.uniq
  end


end

