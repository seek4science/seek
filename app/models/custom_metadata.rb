class CustomMetadata < ApplicationRecord
  include Seek::JSONMetadata::Serialization

  belongs_to :item, polymorphic: true
  belongs_to :custom_metadata_type, validate: true


  has_many :custom_metadata_resource_links, inverse_of: :custom_metadata, dependent: :destroy
  has_many :linked_custom_metadatas, through: :custom_metadata_resource_links, source: :resource, source_type: 'CustomMetadata', dependent: :destroy

  validates_with CustomMetadataValidator
  validates_associated :linked_custom_metadatas

  delegate :custom_metadata_attributes, to: :custom_metadata_type


  after_create :update_linked_custom_metadata_id, if: :has_linked_custom_metadatas?

  def update_linked_custom_metadata_id
    linked_custom_metadatas.each do |cm|
      attr_name = cm.custom_metadata_type.title
      data.mass_assign(data.to_hash.update({attr_name => cm.id}), pre_process: false)
       puts "data:=>"+data.inspect
      update_column(:json_metadata, data.to_json)
    end
  end

  def has_linked_custom_metadatas?
    !linked_custom_metadatas.blank?
  end


  # for polymorphic behaviour with sample
  alias_method :metadata_type, :custom_metadata_type

  def custom_metadata_type=(type)
    super
    @data = Seek::JSONMetadata::Data.new(type)
    update_json_metadata
    type
  end

  def attribute_class
    CustomMetadataAttribute
  end


  def set_linked_custom_metadatas(cma, cm_params)
      if item.new_record?
        self.linked_custom_metadatas.build(custom_metadata_type: cma.linked_custom_metadata_type,
                                           data: cm_params[:data][cma.linked_custom_metadata_type.title.to_sym][:data])
      else
        linked_cm = CustomMetadata.find(self.data[cma.title])
        permitted = cm_params[:data][cma.linked_custom_metadata_type.title.to_sym].require(:data).permit!.to_hash.to_json
        linked_cm.update_attribute(:json_metadata, permitted)
      end
  end

end
