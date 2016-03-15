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
  end

  acts_as_asset

  belongs_to :sample_type
  belongs_to :originating_data_file, :class_name => 'DataFile'

  scope :default_order, order("title")

  validates :title, :sample_type, presence: true
  include ActiveModel::Validations
  validates_with SampleAttributeValidator

  after_initialize :setup_accessor_methods, :read_json_metadata, unless: 'sample_type.nil?'

  before_save :set_json_metadata
  before_validation :set_title_to_title_attribute_value

  def sample_type=(type)
    remove_accessor_methods if sample_type
    super(type)
    setup_accessor_methods if type
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
    hash = Hash[sample_type.sample_attributes.map do |attribute|
      [attribute.parameterised_title, send(attribute.accessor_name)]
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

end
