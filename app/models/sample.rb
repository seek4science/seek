class Sample < ActiveRecord::Base
  attr_accessible :contributor_id, :contributor_type, :json_metadata, :policy_id, :sample_type_id, :title, :uuid

  acts_as_uniquely_identifiable

  belongs_to :sample_type

  validates :title, :sample_type, presence: true

  after_initialize :setup_accessor_methods, unless: 'sample_type.nil?'

  def sample_type=(type)
    remove_accessor_methods if sample_type
    super(type)
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
end
