class ExternalAsset < ActiveRecord::Base
  belongs_to :seek_entity, polymorphic: true

  has_one :content_blob, as: :asset, dependent: :destroy

  validates :external_id, uniqueness: { scope: :external_service }
  validates :external_service, uniqueness: { scope: :external_id }

  before_save :save_content

  def content=(content)
    raise 'Content must be a String' unless content.is_a? String
    init_content_holder
    content_blob.data = content
  end

  def content
    return nil if content_blob.nil?
    content_blob.read
  end

  def init_content_holder()
    if content_blob.nil?
      build_content_blob({
                             url: external_service+ '#' + external_id,
                             original_filename: external_id,
                             make_local_copy: false,
                             external_link: false })
    end
  end

  def save_content
    content_blob.save! unless content_blob.nil?
  end
end
