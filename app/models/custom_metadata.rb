class CustomMetadata < ApplicationRecord

  belongs_to :item, polymorphic: true
  has_many :custom_metadata_attributes

  before_validation :update_json_metadata

  def get_attribute_value(attr)
    attr = attr.accessor_name if attr.is_a?(CustomMetadataAttribute)

    data[attr]
  end

  def set_attribute_value(attr, value)
    attr = attr.accessor_name if attr.is_a?(CustomMetadataAttribute)

    data[attr] = value
  end

  def data
    @data ||= build_json_hash
  end

  private

  def build_json_hash
    if json_metadata
      JSON.parse(json_metadata)
    else
      Hash[custom_metadata_attributes.map{|attr| [attr.title,nil]}]
    end
  end

  def update_json_metadata
    self.json_metadata = data.to_json
  end

end