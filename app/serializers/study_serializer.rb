class StudySerializer < PCSSerializer
  attributes :title, :description, :experimentalists
  attribute :person_responsible_id do
    object.person_responsible_id.to_s
  end
end
