class BaseSerializer
  include JSONAPI::Serializer

  include ApiHelper
  include RelatedItemsHelper

  def self_link
    "#{base_url}/#{type}/#{id}"
  end

  def base_url
    "http://checking.if.this.works.com"
  end
end