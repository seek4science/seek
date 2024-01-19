# Template class for the creation of Sample Type Templates
class Template < ApplicationRecord
  acts_as_asset

  has_many :template_attributes, -> { order(:pos) }, inverse_of: :template, dependent: :destroy
  has_many :sample_types
  has_many :samples, through: :sample_types
  has_many :children, class_name: 'Template', foreign_key: 'parent_id'
  belongs_to :parent, class_name: 'Template', optional: true

  validates :title, presence: true
  validates :title, uniqueness: { scope: %i[group version] }
  validates :level, presence: true
  validate :validate_template_attributes

  accepts_nested_attributes_for :template_attributes, allow_destroy: true

  def can_delete?(user = User.current_user)
    super && sample_types.empty?
  end

  def can_edit?(user = User.current_user)
    super && sample_types.empty?
  end

  def self.can_create?
    can = User.logged_in_and_member? && Seek::Config.samples_enabled
    can && User.current_user.is_admin_or_project_administrator?
  end

  def resolve_inconsistencies
    resolve_controlled_vocabs_inconsistencies
  end

  def validate_template_attributes
    unless attributes_with_empty_isa_tag.none?
      attributes_with_empty_isa_tag.map do |attribute|
        errors.add("[#{:template_attributes}]:", "Attribute '#{attribute.title}' is missing an ISA tag")
      end
    end

    if test_tag_occurences.any?
      test_tag_occurences.map do |tag|
        attributes_with_duplicate_tags = template_attributes.select { |tat| tat.isa_tag&.title == tag }.map(&:title)
        errors.add("[#{:template_attributes}]:",
                   "The '#{tag}' ISA Tag was used in these attributes => #{attributes_with_duplicate_tags.inspect}. This ISA tag is not allowed to be used more then once!")
      end
    end

    test_input_occurence
    test_attribute_title_uniqueness
  end

  private

  # fixes the consistency of the attribute controlled vocabs where the attribute doesn't match.
  # this is to help when a controlled vocab has been selected in the form, but then the type has been changed
  # rather than clearing the selected vocab each time
  def resolve_controlled_vocabs_inconsistencies
    template_attributes.each do |attribute|
      attribute.sample_controlled_vocab = nil unless attribute.sample_attribute_type.controlled_vocab?
    end
  end

  def attributes_with_empty_isa_tag
    template_attributes.select { |ta| !ta.title.include?('Input') && ta.isa_tag_id.nil? }
  end

  def test_tag_occurences
    %w[source protocol sample data_file other_material].map do |tag|
      tag if template_attributes.reject { |ta| ta.title.include?('Input') }.map(&:isa_tag).compact.map(&:title).count(tag) > 1
    end.compact
  end

  def test_input_occurence
    return if template_attributes.map(&:title).map(&:downcase).compact.count('input') <= 1

    errors.add(:base, '[Template attribute]: You are not allowed to have more than one Input attribute.')
  end

  def test_attribute_title_uniqueness
    template_attribute_titles = template_attributes.map(&:title).uniq
    template_attribute_titles.map do |tat|
      if template_attributes.select { |ta| ta.title.downcase == tat.downcase }.map(&:title).count > 1
        errors.add(:template_attributes, "Attribute names must be unique, there are duplicates of #{tat}")
        return tat
      end
    end
  end

  def isa_tag_white_list(template_level)
    case template_level
    when 'study source'
      [Seek::ISA::TagType::SOURCE,
       Seek::ISA::TagType::SOURCE_CHARACTERISTIC]
    when 'study sample'
      [Seek::ISA::TagType::SAMPLE,
       Seek::ISA::TagType::SAMPLE_CHARACTERISTIC,
       Seek::ISA::TagType::PROTOCOL,
       Seek::ISA::TagType::PARAMETER_VALUE]
    when 'assay - material'
      [Seek::ISA::TagType::OTHER_MATERIAL,
       Seek::ISA::TagType::OTHER_MATERIAL_CHARACTERISTIC,
       Seek::ISA::TagType::PROTOCOL,
       Seek::ISA::TagType::PARAMETER_VALUE]
    when 'assay - data file'
      [Seek::ISA::TagType::PROTOCOL,
       Seek::ISA::TagType::DATA_FILE,
       Seek::ISA::TagType::DATA_FILE_COMMENT,
       Seek::ISA::TagType::PARAMETER_VALUE]
    else
      []
    end
  end
end
