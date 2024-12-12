class IsaTag < ApplicationRecord
  validates :title, presence: true

  has_many :template_attributes, inverse_of: :isa_tag
  has_many :sample_attributes, inverse_of: :isa_tag

  def isa_source?
    title == Seek::Isa::TagType::SOURCE
  end

  def isa_source_characteristic?
    title == Seek::Isa::TagType::SOURCE_CHARACTERISTIC
  end

  def isa_sample?
    title == Seek::Isa::TagType::SAMPLE
  end

  def isa_sample_characteristic?
    title == Seek::Isa::TagType::SAMPLE_CHARACTERISTIC
  end

  def isa_protocol?
    title == Seek::Isa::TagType::PROTOCOL
  end

  def isa_other_material?
    title == Seek::Isa::TagType::OTHER_MATERIAL
  end

  def isa_other_material_characteristic?
    title == Seek::Isa::TagType::OTHER_MATERIAL_CHARACTERISTIC
  end

  def isa_data_file?
    title == Seek::Isa::TagType::DATA_FILE
  end

  def isa_data_file_comment?
    title == Seek::Isa::TagType::DATA_FILE_COMMENT
  end

  def isa_parameter_value?
    title == Seek::Isa::TagType::PARAMETER_VALUE
  end

  def self.allowed_isa_tags_for_level(level)
    tags = case level
    when 'study source'
      Seek::Isa::TagType::SOURCE_TAGS
    when 'study sample'
      Seek::Isa::TagType::SAMPLE_TAGS
    when 'assay - material'
      Seek::Isa::TagType::OTHER_MATERIAL_TAGS
    when 'assay - data file'
      Seek::Isa::TagType::DATA_FILE_TAGS
    else
      Seek::Isa::TagType::ALL_TYPES
    end

    tags.map { |tag| IsaTag.find_by(title: tag) }
  end
end
