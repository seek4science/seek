class Sample < ActiveRecord::Base
  attr_accessible :contributor_id, :contributor_type, :json_metadata, :policy_id, :sample_type_id, :title, :uuid

  acts_as_uniquely_identifiable

  belongs_to :sample_type

  validates :title, :sample_type, presence: true

  after_initialize :setup_accessor_methods, :setup_validations, unless: 'sample_type.nil?'

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
end
