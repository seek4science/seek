class WorkflowClass < ApplicationRecord
  include HasCustomAvatar

  has_many :workflows, inverse_of: :workflow_class
  has_many :workflow_versions, class_name: 'Workflow::Version', inverse_of: :workflow_class
  belongs_to :contributor, class_name: 'Person', optional: true

  before_validation :assign_and_format_key, on: [:create]
  after_update :remove_old_avatars

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
    m['identifier'] = { '@id' => identifier } if identifier.present?
    m['url'] = { '@id' => url } if url.present?

    m
  end

  # Match priority: identifier, name (title), alternateName (alternate_name), @id (key), url
  def self.match_from_metadata(metadata)
    match = nil

    iden = metadata.dig('identifier')
    iden = iden['@id'] unless iden.nil? || iden.is_a?(String)
    match = where(identifier: iden).first if iden.present?
    return match if match

    names = [metadata['name'], metadata['alternateName']].compact
    if names.any?
      match = where(title: names).first
      return match if match

      match = where(alternate_name: names).first
      return match if match
    end

    match = where(key: metadata['@id']&.sub('#', '')).first
    return match if match

    u = metadata.dig('url')
    u = u['@id'] unless u.nil? || u.is_a?(String)
    match = where(url: u).first if u.present?
    return match if match

    match
  end

  def self.can_create?
    User.logged_in?
  end

  def can_delete?(user = User.current_user)
    can_manage? && workflows.empty? && workflow_versions.empty?
  end

  def can_manage?(user = User.current_user)
    user && (user.is_admin? || user.person == contributor)
  end

  def can_edit?(_user = User.current_user)
    can_manage?
  end

  def defines_own_avatar?
    avatar_id.present?
  end

  def avatar_key
    extractor&.present? ? "#{key.downcase}_workflow" : 'workflow'
  end

  def logo_image=(image_file)
    self.avatar = avatars.build(image_file: image_file)
  end

  private

  def assign_and_format_key
    k = self.key ? self.key.underscore.downcase : self.class.generate_key(title.parameterize.underscore)
    self.key = k
  end

  def self.generate_key(suggested_key)
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

  def remove_old_avatars
    avatars.each do |a|
      a.destroy unless a == avatar # don't remove the selected avatar
    end
  end
end
