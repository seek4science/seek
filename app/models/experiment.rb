require 'grouped_pagination'
require 'acts_as_authorized'

class Experiment < ActiveRecord::Base
  belongs_to :sample

  belongs_to :institution
  belongs_to :assay
  has_many :assets_creators, :dependent => :destroy, :as => :asset, :foreign_key => :asset_id
  has_many :creators, :class_name => "Person", :through => :assets_creators, :order=>'assets_creators.id'


  has_and_belongs_to_many :data_files

  has_many :relationships,
           :class_name => 'Relationship',
           :as => :subject,
           :dependent => :destroy

  validates_presence_of :title,:project,:institution,:contributor,:date,:description,:sample
  validates_uniqueness_of :title
  alias_attribute :data_file_masters, :data_files


  grouped_pagination :pages=>("A".."Z").to_a, :default_page => Seek::Config.default_page(self.name.underscore.pluralize)
  acts_as_authorized

  def related_publications
    self.relationships.select { |a| a.object_type == "Publication" }.collect { |a| a.object }
  end

end
