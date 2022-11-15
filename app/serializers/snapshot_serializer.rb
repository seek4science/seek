class SnapshotSerializer < BaseSerializer

  attributes :md5sum, :sha1sum, :snapshot_number
  attributes :title, :description

  has_one :contributor
  has_many :people

  link(:self) { polymorphic_path([object.parent, object]) }
  link(:download) { polymorphic_path([:download, object.parent, object]) }
end
