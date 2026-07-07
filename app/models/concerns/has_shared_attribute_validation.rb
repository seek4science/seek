# frozen_string_literal: true

module HasSharedAttributeValidation
  extend ActiveSupport::Concern

  included do
    validates :title, presence: true
    validates :title, length: { maximum: 255 }
    validates :description, length: { maximum: 65_535 }
    validates :contributor, presence: true
    validates :projects, presence: true, projects: { self: true }
    validate :validate_one_title_attribute_present,
             :validate_attribute_title_unique,
             :validate_title_is_not_type_of_seek_sample_multi

  end
  private

  def shared_attributes
    is_a?(Template) ? template_attributes : sample_attributes
  end

  def shared_attributes_name
    is_a?(Template) ? :template_attributes : :sample_attributes
  end

  def validate_one_title_attribute_present
    unless (count = shared_attributes.select(&:is_title).count) == 1
      errors.add(shared_attributes_name, "There must be 1 attribute which is the title, currently there are #{count}")
    end
  end

  def validate_attribute_title_unique
    # TODO: would like to have done this with uniqueness{scope: :sample_type_id} on the attribute, but that leads to an exception when being added
    # to the sample type
    titles = attribute_titles.collect(&:downcase)
    dups = titles.select { |title| titles.count(title) > 1 }.uniq
    if dups.any?
      dups_text = dups.join(', ')
      errors.add(shared_attributes_name, "Attribute names must be unique, there are duplicates of #{dups_text}")
    end
  end

  def attribute_titles
    shared_attributes.collect(&:title)
  end

  def validate_title_is_not_type_of_seek_sample_multi
    base_type = Seek::Samples::BaseType::SEEK_SAMPLE_MULTI
    is_title_seek_sample_multi = shared_attributes.find(&:is_title)&.sample_attribute_type&.base_type == base_type
    if is_title_seek_sample_multi
      errors.add(shared_attributes_name, "Attribute type of #{base_type.underscore.humanize} can not be selected as the #{self.class.name} title.")
    end
  end

  # fixes the consistency of the attribute controlled vocabs where the attrcibute doesn't match.
  # this is to help when a controlled vocab has been selected in the form, but then the type has been changed
  # rather than clearing the selected vocab each time
  def resolve_controlled_vocabs_inconsistencies
    shared_attributes.each do |attribute|
      attribute.sample_controlled_vocab = nil unless attribute.controlled_vocab? || attribute.seek_cv_list?
    end
  end
end
