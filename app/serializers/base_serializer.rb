class BaseSerializer
  include JSONAPI::Serializer

  def self_link
    "/api/v1#{super}"
  end
end