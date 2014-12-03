
require 'acts_as_versioned_resource'
require 'explicit_versioning'
require 'title_trimmer'
require 't2flow/model'
require 't2flow/parser'
require 't2flow/dot'

class Workflow < ActiveRecord::Base

  acts_as_asset

  include Seek::Dois::DoiGeneration

  scope :default_order, order('title')

  title_trimmer

  validates_presence_of :title

  validates :myexperiment_link, :format => { :with => /^http:\/\/(www\.)?myexperiment\.org\/workflows\/[0-9]+/,
                                             :message => "is invalid, please make sure the URL is in the format: http://www.myexperiment.org/workflows/...",
                                             :allow_blank => true }


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

    def has_interaction?
      t2flow.all_processors.any? {|p| p.type == 'interaction'}
    end

    def result_output_ports
      output_ports.select { |output| (output.port_type.name == WorkflowOutputPortType::RESULT) }.sort_by { |p| p.name.downcase }
    end

    def error_log_output_ports
      output_ports.select { |output| (output.port_type.name == WorkflowOutputPortType::ERROR_LOG) }.sort_by { |p| p.name.downcase }
    end

    def data_input_ports
      input_ports.select { |input| (input.port_type.name == WorkflowInputPortType::DATA) }.sort_by { |p| p.name.downcase }
    end

    def parameter_input_ports
      input_ports.select { |input| (input.port_type.name == WorkflowInputPortType::PARAMETER) }.sort_by { |p| p.name.downcase }
    end

    def sweepable_from_run?
      sweepable && data_input_ports.size > 0
    end

    def sweepable?
      sweepable_from_run? && !has_interaction?
    end

    def can_run?(user = User.current_user)
      !user.nil? # just checks if user is logged in for now
    end
  end

  searchable(:ignore_attribute_changes_of=>[:updated_at]) do
    text :category
  end if Seek::Config.solr_enabled

  def self.user_creatable?
    Seek::Config.workflows_enabled
  end

  def t2flow
    @t2flow ||= T2Flow::Parser.new.parse(content_blob.data_io_object.read)
  end

  def file_path
    content_blob.filepath
  end

  def has_interaction?
    t2flow.all_processors.any? {|p| p.type == 'interaction'}
  end

  def self.by_category(cid)
    where(:category_id => cid)
  end

  def self.by_uploader(uid)
    where(:contributor_id => uid, :contributor_type => "User")
  end

  def self.by_visibility(visibility)
    if visibility == 'public'
      joins(:policy).where(:policies => {:sharing_scope => 4})
    elsif visibility == 'private'
      joins(:policy).where(:policies => {:sharing_scope => 0, :access_type => 0}).by_uploader(User.current_user.id)
    elsif visibility == "registered"
      joins(:policy).where('policies.sharing_scope = 2 AND policies.access_type > 0')
    else
      match = visibility.match(/(.*):(.*)/)
      puts match.inspect
      joins(:policy => :permissions).where(:policies => {:access_type => 0},
                                           :permissions => {:contributor_type => match[1],
                                                            :contributor_id => match[2].to_i})
    end
  end

  def uploader
    if :contributor_type == 'User'
      return self.contributor.person.name
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

  def default_policy
    Policy.private_policy
  end

  def result_output_ports
    output_ports.select { |output| (output.port_type.name == WorkflowOutputPortType::RESULT) }.sort_by { |p| p.name.downcase }
  end

  def error_log_output_ports
    output_ports.select { |output| (output.port_type.name == WorkflowOutputPortType::ERROR_LOG) }.sort_by { |p| p.name.downcase }
  end

  def data_input_ports
    input_ports.select { |input| (input.port_type.name == WorkflowInputPortType::DATA) }.sort_by { |p| p.name.downcase }
  end

  def parameter_input_ports
    input_ports.select { |input| (input.port_type.name == WorkflowInputPortType::PARAMETER) }.sort_by { |p| p.name.downcase }
  end

  def sweepable_from_run?
    sweepable && data_input_ports.size > 0
  end

  def sweepable?
    sweepable_from_run? && !has_interaction?
  end

  def can_run?(user = User.current_user)
    !user.nil? # just checks if user is logged in for now
  end

end