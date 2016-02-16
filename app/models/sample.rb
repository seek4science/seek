class Sample < ActiveRecord::Base
  attr_accessible :contributor_id, :contributor_type, :json_metadata, :policy_id, :sample_type_id, :title, :uuid

  acts_as_uniquely_identifiable

  belongs_to :sample_type

  validates :title, :sample_type, presence: true
  include ActiveModel::Validations
  validates_with SampleAttributeValidator

  after_initialize :setup_accessor_methods, :read_json_metadata, unless: 'sample_type.nil?'

  before_save :set_json_metadata

  def sample_type=(type)
    remove_accessor_methods if sample_type
    super(type)
    setup_accessor_methods if type
  end

  #TODO: add unit test, must test for passing none attributes
  def read_attributes_from_params params
    return unless sample_type
    sample_type.sample_attributes.collect(&:accessor_name).each do |name|
      val = params[name.to_sym]
      self.send("#{name}=",val)
    end
  end

  private

  def setup_accessor_methods
    sample_type.sample_attributes.collect(&:accessor_name).each do |name|
      class_eval <<-END_EVAL
          attr_accessor '#{name}'
        END_EVAL
    end

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
      [attribute.accessor_name, send(attribute.accessor_name)]
    end]
    self.json_metadata = hash.to_json
  end

  def read_json_metadata
    if sample_type && json_metadata
      json = JSON.parse(json_metadata)
      sample_type.sample_attributes.collect(&:accessor_name).each do |accessor_name|
        send("#{accessor_name}=", json[accessor_name])
      end
    end
  end
end
