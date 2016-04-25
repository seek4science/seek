class Sample < ActiveRecord::Base
  attr_accessible :contributor_id, :contributor_type, :json_metadata,
                  :policy_id, :sample_type_id, :sample_type, :title, :uuid, :project_ids, :policy, :contributor,
                  :other_creators

  searchable(:auto_index=>false) do
    text :attribute_values do
      attribute_values_for_search
    end
    text :sample_type do
      sample_type.title
    end
  end if Seek::Config.solr_enabled

  acts_as_asset

  belongs_to :sample_type, inverse_of: :samples
  belongs_to :originating_data_file, :class_name => 'DataFile'

  scope :default_order, order("title")

  validates :title, :sample_type, presence: true
  include ActiveModel::Validations
  validates_with SampleAttributeValidator

  #after_initialize :setup_accessor_methods, :read_json_metadata, unless: 'sample_type.nil?'

  before_save :set_json_metadata
  before_validation :set_title_to_title_attribute_value

  def sample_type=(type)
    super
    self.json_metadata = nil
    @metadata = nil
  end

  def is_in_isa_publishable?
    false
  end

  def self.can_create?
    User.logged_in_and_member?
  end


  def self.user_creatable?
    true
  end

  def related_data_file
    originating_data_file
  end

  def metadata
    if @metadata.blank?
      if json_metadata.blank?
        if sample_type.nil?
          @metadata = {}
        else
          @metadata = JSON.parse(set_json_structure)
        end
      else
        @metadata = JSON.parse(json_metadata)
      end
    else
      @metadata
    end
  end

  private

  def attribute_values_for_search
    return [] unless self.sample_type
    self.sample_type.sample_attributes.collect do |attr|
      self.send(attr.accessor_name).to_s
    end.reject{|val| val.blank?}.uniq
  end

  def setup_accessor_methods
    sample_type.sample_attributes.collect(&:accessor_name).each do |name|
      class_eval <<-END_EVAL
          attr_accessor '#{name}'
        END_EVAL
    end
  end

  # overrdie to insert the extra accessors for mass assignment
  def mass_assignment_authorizer(role)
    extra = []
    if sample_type
      extra = sample_type.sample_attributes.collect(&:accessor_name)
    end
    super(role) + extra
  end

  def remove_accessor_methods
    sample_type.sample_attributes.collect(&:accessor_name).each do |name|
      class_eval <<-END_EVAL
          undef_method '#{name}'
          undef_method '#{name}='
      END_EVAL
    end
  end

  def set_json_metadata
    self.json_metadata = @metadata.to_json
  end

  def set_json_structure
    hash = Hash[sample_type.sample_attributes.map do |attribute|
      [attribute.accessor_name, nil]
    end]
    self.json_metadata = hash.to_json
  end

  def read_json_metadata
    if sample_type && json_metadata
      json = JSON.parse(json_metadata)
      sample_type.sample_attributes.each do |attribute|
        send("#{attribute.accessor_name}=", json[attribute.parameterised_title])
      end
    end
  end

  def set_title_to_title_attribute_value
    self.title = title_attribute_value
  end

  #the value of the designated title attribute
  def title_attribute_value
    return nil unless (sample_type && sample_type.sample_attributes.title_attributes.any?)
    title_attr=sample_type.sample_attributes.title_attributes.first
    self.send(title_attr.accessor_name)
  end

  def respond_to_missing?(method_name, include_private = false)
    if metadata.keys.include?(method_name.to_s.chomp('='))
      true
    else
      super
    end
  end

  def method_missing(method_name, *args)
    setter = method_name.to_s.end_with?('=')
    attribute_name = method_name.to_s.chomp('=')

    if metadata.key?(attribute_name)
      metadata[attribute_name] = attribute_for_attribute_name(attribute_name).pre_process_value(args.first) if setter
      metadata[attribute_name]
    else
      super
    end
  end

  def attribute_for_attribute_name(attribute_name)
    sample_type.sample_attributes.where(accessor_name:attribute_name).first
  end

end
