# Serialize an an asset_version (DataFile::Version)
class VersionSerializer < ContributedResourceSerializer
  #Get the id and type of the original asset, not the version.
  def id
    if defined?(object.parent)
      object.parent.id.to_s
    else
      object.id.to_s
    end
  end

  def type
    if defined?(object.parent)
      object.parent.class.name.demodulize.tableize
    else
      object.class.name.demodulize.tableize
    end
  end

  attribute :current_revision_comments do
    object.revision_comments
  end
end

class DataFile::VersionSerializer < VersionSerializer
  type :data_files

  has_many :people
  has_many :projects
  has_many :investigations
  has_many :studies
  has_many :assays
  has_many :publications
  has_many :events
  has_many :samples
end

class Sop::VersionSerializer < VersionSerializer
  type :sops

  has_many :people
  has_many :projects
  has_many :investigations
  has_many :studies
  has_many :assays
  has_many :publications

end

class Presentation::VersionSerializer < VersionSerializer
  type :presentations

  has_many :people
  has_many :projects
  has_many :investigations
  has_many :studies
  has_many :assays
  has_many :publications
  has_many :events

end

class Model::VersionSerializer < VersionSerializer
  type :models

  has_many :people
  has_many :projects
  has_many :investigations
  has_many :studies
  has_many :assays
  has_many :publications

end

# class VersionSerializer < BaseSerializer
#   attributes :title, :description, :doi, :license,
#              :revision_comments, :template_name, :is_with_sample
#   def id
#     object.version
#   end
# end
