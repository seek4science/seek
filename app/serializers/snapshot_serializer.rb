class SnapshotSerializer < BaseSerializer
  attributes :snapshot_number, :title, :description, :md5sum, :sha1sum, :doi_identifier

  def self_link
    polymorphic_path([object.resource, object])
  end
end
