# Template class for the creation of Sample Type Templates
class Template < ApplicationRecord
  acts_as_asset

  include HasSharedAttributeValidation

  has_many :template_attributes, -> { order(:pos) }, inverse_of: :template, dependent: :destroy
  has_many :sample_types
  has_many :samples, through: :sample_types
  has_many :children, class_name: 'Template', foreign_key: 'parent_id'
  belongs_to :parent, class_name: 'Template', optional: true

  validates :title, presence: true
  validates :title, uniqueness: { scope: %i[group version] }
  validates :level, presence: true
  validate :validate_template_level
  validate :validate_no_attributes_with_empty_isa_tag, if: -> { errors.blank? }
  validate :validate_isa_tags, if: -> { errors.blank? }

  accepts_nested_attributes_for :template_attributes, allow_destroy: true
  scope :for_sample_type_creation, -> { where.not(group: Seek::ISATemplates::TemplateGroup::EXCLUDED_FROM_SAMPLE_TYPE_CREATION) }

  has_filter :isa_template_group
  def can_delete?(user = User.current_user)
    super && sample_types.empty? && children.none?
  end

  def can_edit?(user = User.current_user)
    super && sample_types.empty?
  end

  def self.can_create?
    super && Seek::Config.samples_enabled && User.current_user.is_admin_or_project_administrator?
  end

  def resolve_inconsistencies
    resolve_controlled_vocabs_inconsistencies
  end

  private

  def validate_template_level
    unless Seek::ISATemplates::TemplateLevel.valid?(level)
      errors.add :level, "is not a valid #{t('template')} level"
    end
  end

  def validate_no_attributes_with_empty_isa_tag
    template_attributes.each do |attribute|
      if attribute.isa_tag_id.blank?
        errors.add(:template_attributes, "Attribute '#{attribute.title}' is missing an ISA tag")
      end
    end
  end

  def validate_isa_tags
    tags_for_level = ISATag.allowed_isa_tags_for_level(level)
    tags_exactly_one = tags_for_level.select { |tag| Seek::ISA::TagType.exactly_one?(tag&.title) }

    template_attributes.each do |attribute|
      isa_tag = attribute.isa_tag

      # Test for invalid ISA tags
      unless tags_for_level.pluck(:title).include? isa_tag.title
        errors.add(:template_attributes, "ISA Tag '#{isa_tag.title}' for attribute '#{attribute.title}' is not allowed.")
      end
    end

    # Test for ISA tags that are allowed to be added only once
    tags_exactly_one.each do |tag|
      unless (count = template_attributes.select { |ta| ta.isa_tag.title == tag.title }.count) == 1
        errors.add(:template_attributes, "You must have exactly one attribute with a '#{tag.title}' ISA Tag. Currently, #{count} attributes found.")
      end
    end
  end

  # @todo: This is probably not used anywhere and can be deleted in the future. For now, this is just calling the method in the ISATag::TagType module.
  def isa_tag_white_list(template_level)
    ISATag.allowed_isa_tags_for_level(template_level)
  end

  def self.supports_extended_metadata?
    false
  end

end
