class WorkflowClass < ApplicationRecord
  belongs_to :contributor, class_name: 'Person', optional: true

  before_validation :assign_key

  validates :title, uniqueness: true
  validates :key, uniqueness: true
  validate :extractor_valid?

  def extractor_class
    extractor ? self.class.const_get("Seek::WorkflowExtractors::#{extractor}") : Seek::WorkflowExtractors::Base
  end

  def extractable?
    extractor.present?
  end

  def self.extractable
    where.not(extractor: nil)
  end

  def self.unextractable
    where(extractor: nil)
  end

  def ro_crate_metadata
    m = {
        "@id" => "##{key}",
        "@type" => "ComputerLanguage",
        "name" => title
    }

    m['alternateName'] = alternate_name if alternate_name.present?
    m['identifier'] = identifier if identifier.present?
    m['url'] = url if url.present?

    m
  end

  private

  def assign_key
    return if key.present?
    self.key = self.class.unique_key(title.parameterize.underscore.camelize)
  end

  def self.unique_key(suggested_key)
    extra = 0
    key = suggested_key
    while where(key: key).exists? do
      key = "#{suggested_key}#{extra += 1}"
    end

    key
  end

  def extractor_valid?
    return if extractor.nil?
    begin
      self.class.const_get("Seek::WorkflowExtractors::#{extractor}")
    rescue NameError
      errors.add(:extractor, "was not a valid format")
    end
  end
end
