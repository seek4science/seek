class SkeletonSerializer < ActiveModel::Serializer
  include Seek::Util.routes

  attribute :title

  def self_link
    polymorphic_path(object)
  end

  def _links
    { self: self_link }
  end

end