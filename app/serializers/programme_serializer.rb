class ProgrammeSerializer < AvatarObjSerializer
  attributes :title, :description,
             :web_page,
             :funding_details

  attribute :tags, key: :funding_codes do
    serialize_annotations(object, context = 'funding_code')
  end
  has_many :administrators

  include_related_items

  def administrators
    object.programme_administrators
  end
end
