require 'acts_as_asset'
require 'acts_as_versioned_resource'
require 'explicit_versioning'
require 'title_trimmer'

class Workflow < ActiveRecord::Base

  acts_as_asset
  acts_as_trashable

  scope :default_order, order('title')

  title_trimmer

  validates_presence_of :title

  after_save :queue_background_reindexing if Seek::Config.solr_enabled

  belongs_to :category, :class_name => 'WorkflowCategory'
  has_many :input_ports, :class_name => 'WorkflowInputPort'
  has_many :output_ports, :class_name => 'WorkflowOutputPort'
  has_one :content_blob, :as => :asset, :foreign_key => :asset_id, :conditions => Proc.new { ["content_blobs.asset_version =?", version] }

  def self.user_creatable?
    true
  end

  def self.get_all_as_json(user)
    all = Workflow.all_authorized_for "view", user
    with_contributors = all.collect { |d|
      contributor = d.contributor;
      {"id" => d.id,
       "title" => h(d.title),
       "contributor" => contributor.nil? ? "" : "by " + h(contributor.person.name),
       "type" => self.name
      }
    }
    return with_contributors.to_json
  end

end