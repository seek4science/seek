require 'digest/sha1'
class PersonSerializer < AvatarObjSerializer
  attributes :title, :description,
             :first_name, :last_name, :orcid,
             :mbox_sha1sum

  attribute :expertise do
    serialize_annotations(object, context = 'expertise')
  end
  attribute :tools do
    serialize_annotations(object, context = 'tool')
  end

  attribute :orcid do
    object.orcid_uri
  end

  attribute :project_positions do
    positions = []
    object.group_memberships.each do |gm|
      gm.project_positions.each do |pos|
        positions.append({ project_id: gm.project.id.to_s,
                    position_id:  pos.id.to_s,
                    position_name: pos.name })
      end
    end
    positions
  end

  has_many :projects
  has_many :institutions
  has_many :investigations
  has_many :studies
  has_many :assays
  has_many :data_files
  has_many :models
  has_many :sops
  has_many :publications
  has_many :presentations
  has_many :events
  has_many :documents
end
