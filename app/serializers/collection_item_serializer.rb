class CollectionItemSerializer < ActiveModel::Serializer
  has_one :asset, polymorphic: true

  attributes :comment, :order

  def base_url
    Seek::Config.site_base_host
  end
end
