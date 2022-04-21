class SkeletonSerializer < ActiveModel::Serializer
  include Seek::Util.routes

  attribute :title

  link(:self) { polymorphic_path(object) }
end