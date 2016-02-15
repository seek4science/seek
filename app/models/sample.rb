class Sample < ActiveRecord::Base
  attr_accessible :contributor_id, :contributor_type, :json_metadata, :policy_id, :sample_type_id, :title, :uuid

  acts_as_uniquely_identifiable

  belongs_to :sample_type

  validates :title, :sample_type, presence: true

  after_initialize :setup_accessor_methods, :setup_validations,:read_json_metadata, unless: 'sample_type.nil?'

  before_save :set_json_metadata

  def sample_type=(type)
    remove_accessor_methods if sample_type
    super(type)
    setup_validations if type
    setup_accessor_methods if type
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

  def setup_validations
    sample_type.sample_attributes.each do |attribute|
      class_eval <<-END_EVAL
          if #{attribute.required?}
            validates '#{attribute.accessor_name}', presence:true
          end
          validate '#{attribute.accessor_name}', '#{attribute.accessor_name}_validator'
          def #{attribute.accessor_name}_validator
            unless sample_type.validate_value?('#{attribute.title}',#{attribute.accessor_name})
              errors.add('#{attribute.accessor_name}','is not a valid #{attribute.sample_attribute_type.title}')
            end
          end
      END_EVAL
    end
  end

  def set_json_metadata
    hash = Hash[sample_type.sample_attributes.map do |attribute|
      [attribute.accessor_name,self.send(attribute.accessor_name)]
    end]
    self.json_metadata = hash.to_json
  end

  def read_json_metadata
    if sample_type && self.json_metadata
      json = JSON.parse(self.json_metadata)
      sample_type.sample_attributes.collect(&:accessor_name).each do |accessor_name|
        send("#{accessor_name}=",json[accessor_name])
      end
    end
  end
end
