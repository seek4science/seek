class SkeletonSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attribute :title

  def self_link
    polymorphic_path(object)
  end

  def _links
    { self: self_link }
  end

end