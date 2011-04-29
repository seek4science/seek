require 'grouped_pagination'
require 'acts_as_authorized'

class Sample < ActiveRecord::Base
  belongs_to :specimen
#  belongs_to :project
  belongs_to :institution
#  belongs_to :policy
  has_many :experiments

  has_many :assets_creators, :dependent => :destroy, :as => :asset, :foreign_key => :asset_id
  has_many :creators, :class_name => "Person", :through => :assets_creators, :order=>'assets_creators.id'
#  belongs_to :contributor, :polymorphic => true

  alias_attribute :description, :comments
  validates_presence_of :title
  validates_uniqueness_of :title
  validates_presence_of :specimen_id
  validates_presence_of :donation_date

  has_and_belongs_to_many :strains

  grouped_pagination :pages=>("A".."Z").to_a, :default_page => Seek::Config.default_page(self.name.underscore.pluralize)

  acts_as_authorized
end
