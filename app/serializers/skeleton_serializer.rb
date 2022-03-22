class SkeletonSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attribute :title

  link(:self) { polymorphic_path(object) }
end