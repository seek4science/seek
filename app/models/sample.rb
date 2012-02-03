require 'grouped_pagination'
require 'acts_as_authorized'

class Sample < ActiveRecord::Base
 include Subscribable

  attr_accessor :from_new_link

  belongs_to :specimen
  belongs_to :institution
  has_and_belongs_to_many :assays

  has_many :assets_creators, :dependent => :destroy, :as => :asset, :foreign_key => :asset_id
  has_many :creators, :class_name => "Person", :through => :assets_creators, :order=>'assets_creators.id'
  has_many :assets,:through => :sample_assets
  has_many :sample_assets,:dependent => :destroy

  def self.sop_sql()
  'SELECT sop_versions.* FROM sop_versions ' +
  'INNER JOIN sample_sops ' +
  'ON sample_sops.sop_id = sop_versions.sop_id ' +
  'WHERE (sample_sops.sop_version = sop_versions.version ' +
  'AND sample_sops.sample_id = #{self.id})'
  end

  def self.asset_sql(asset_class)
    asset_class_underscored = asset_class.underscore
    'SELECT ' + asset_class_underscored + '_versions.* FROM ' + asset_class_underscored + '_versions ' +
    'INNER JOIN sample_assets ' +
    'ON sample_assets.asset_id= '+ asset_class_underscored + '_id ' +
    'AND sample_assets.asset_type=\'' + asset_class + '\' ' +
    'WHERE (sample_assets.version= ' + asset_class_underscored + '_versions.version ' +
    'AND sample_assets.sample_id= #{self.id})'
  end

  has_many :data_files, :class_name => "DataFile::Version", :finder_sql => self.asset_sql("DataFile")
  has_many :models, :class_name => "Model::Version", :finder_sql => self.asset_sql("Model")
  has_many :sops, :class_name => "Sop::Version", :finder_sql => self.asset_sql("Sop")

  has_many :data_file_masters, :through => :sample_assets, :source => :asset, :source_type => 'DataFile'
  has_many :model_masters, :through => :sample_assets, :source => :asset, :source_type => 'Model'
  has_many :sop_masters, :through => :sample_assets, :source => :asset, :source_type => 'Sop'
  #has_many :sop_masters,:class_name => "SampleSop"


  alias_attribute :description, :comments
  validates_presence_of :title
  validates_uniqueness_of :title
  validates_presence_of :specimen,:lab_internal_number
  validates_presence_of :donation_date

  grouped_pagination :pages=>("A".."Z").to_a, :default_page => Seek::Config.default_page(self.name.underscore.pluralize)

  acts_as_solr(:fields=>[:description,:title,:lab_internal_number],:include=>[:institution,:specimen,:assays]) if Seek::Config.solr_enabled

  acts_as_authorized


 def can_delete? *args
   assays.empty? && super
 end

 def self.user_creatable?
   true
 end


 def associate_asset asset
   sample_asset = sample_assets.detect { |sa| sa.asset == asset }

   unless sample_asset
     sample_asset = SampleAsset.new
     sample_asset.sample = self
     sample_asset.asset = asset
   end

   sample_asset.version = asset.version
   sample_asset.save if sample_asset.changed?

   return sample_asset
 end

 def create_or_update_assets asset_ids, asset_class_name
   asset_class = eval asset_class_name
   existing_sample_assets = sample_assets.select {|sa| sa.asset_type == asset_class_name}
   asset_ids_to_destroy = existing_sample_assets.map(&:asset_id) - asset_ids.map(&:to_i)

   #destroy old,redundant sample_assets
   existing_sample_assets.select{|sa| asset_ids_to_destroy.include? sa.asset_id}.each &:destroy

   #update/create new sample assets
   asset_ids.each do |id|
     asset = asset_class.find id
     associate_asset asset if asset.can_view?
   end

 end

 def clone_with_associations
   new_object= self.clone
   new_object.policy = self.policy.deep_copy
   new_object.data_file_masters = self.data_file_masters.select(&:can_view?)
   new_object.model_masters = self.model_masters.select(&:can_view?)
   new_object.sop_masters = self.sop_masters.select(&:can_view?)
   new_object.project_ids = self.project_ids
   return new_object
 end
end
