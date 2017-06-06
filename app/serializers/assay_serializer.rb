class AssaySerializer < PCSSerializer
  attributes :id, :title, :description,:assay_class
  attribute :assay_type do
    object.assay_type_label
  end
  attribute :technology_type do
    object.technology_type_label
  end
  has_many :organisms, include_data:true
  has_many :assay_organisms, include_data:true
end
