require 'acts_as_asset'
require 'acts_as_versioned_resource'
require 'explicit_versioning'
require 'title_trimmer'
require 't2flow/model'
require 't2flow/parser'
require 't2flow/dot'

class Workflow < ActiveRecord::Base

  acts_as_asset
  acts_as_trashable

  scope :default_order, order('title')

  title_trimmer

  validates_presence_of :title

  after_save :queue_background_reindexing if Seek::Config.solr_enabled

  belongs_to :category, :class_name => 'WorkflowCategory'
  has_many :input_ports, :class_name => 'WorkflowInputPort',
           :conditions => proc { "workflow_version = #{self.version}" },
           :dependent => :destroy

  has_many :output_ports, :class_name => 'WorkflowOutputPort',
           :conditions => proc { "workflow_version = #{self.version}"},
           :dependent => :destroy

  has_one :content_blob, :as => :asset, :foreign_key => :asset_id, :conditions => Proc.new { ["content_blobs.asset_version =?", version] }

  accepts_nested_attributes_for :input_ports, :output_ports

  has_one :content_blob, :as => :asset, :foreign_key => :asset_id, :conditions => Proc.new { ["content_blobs.asset_version =?", version] }

  explicit_versioning(:version_column => "version") do
    acts_as_versioned_resource
    acts_as_favouritable

    has_one :content_blob, :primary_key => :workflow_id, :foreign_key => :asset_id, :conditions => Proc.new { ["content_blobs.asset_version =? AND content_blobs.asset_type =?", version, parent.class.name] }
    has_many :input_ports, :class_name => 'WorkflowInputPort',
             :primary_key => "workflow_id",
             :foreign_key => "workflow_id",
             :conditions => proc { "workflow_version = #{self.version}"},
             :dependent => :destroy

    has_many :output_ports, :class_name => 'WorkflowOutputPort',
             :primary_key => "workflow_id",
             :foreign_key => "workflow_id",
             :conditions => proc { "workflow_version = #{self.version}"},
             :dependent => :destroy

    def content_blobs
      ContentBlob.where(["asset_id =? and asset_type =? and asset_version =?", self.parent.id, self.parent.class.name, self.version])
    end

    def t2flow
      @t2flow ||= T2Flow::Parser.new.parse(content_blob.data_io_object.read)
    end

    def file_path
      content_blob.filepath
    end
  end

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

  def t2flow
    @t2flow ||= T2Flow::Parser.new.parse(content_blob.data_io_object.read)
  end

  def file_path
    content_blob.filepath
  end

  private

  def generate_workflow_image
    img_path = "/images/workflow_images/#{id}v#{version}.svg"
    file_path = "#{Rails.root}/public#{img_path}"
    FileUtils.mkdir("#{Rails.root}/public/images/workflow_images") unless File.exists?("#{Rails.root}/public/images/workflow_images")
    unless File.exists?(file_path)
      i = Tempfile.new("workflowimage#{@workflow.id}")
      T2Flow::Dot.new.write_dot(i, t2flow)
      i.close(false)
      img = StringIO.new(`dot -Tsvg #{i.path}`)
      File.open(file_path,"w") do |f|
        f.write(img.read)
      end
    end
    @workflow_image = img_path
  end

end