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

  has_many :runs, :class_name => "TavernaPlayer::Run", :dependent => :destroy

  has_many :sweeps, :class_name => "Sweep", :dependent => :destroy

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

  searchable(:ignore_attribute_changes_of=>[:updated_at]) do
    text :title , :description, :category, :uploader
  end if Seek::Config.solr_enabled


  def uploader
    return self.contributor.person.name
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

  def self.by_category(cid)
    where(:category_id => cid)
  end

  def self.by_uploader(uid)
    where(:contributor_id => uid, :contributor_type => "User")
  end

  def self.uploader()
    if :contributor_type == 'User'
      return contributor.person.name
    else
      return nil
    end
  end

  # Related items, like runs and sweeps
  def collect_related_items
    related = {'Run' => {}, 'Sweep' => {}}

    related.each_key do |key|
      related[key][:items] = []
      related[key][:hidden_items] = []
      related[key][:hidden_count] = 0
      related[key][:extra_count] = 0
    end

    related_types = related.keys
    related_types.each do |type|
      method_name = type.underscore.pluralize
      if self.respond_to? method_name
        related[type][:items] = self.send method_name
        if method_name == 'runs'
          # Remove all runs that belong to a sweep
          related[type][:items] = related[type][:items].select{ |run| run.sweep_id.blank? }
        end
      end
    end

    related
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