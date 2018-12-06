class SnapshotSerializer < BaseSerializer

  attributes :md5sum, :sha1sum, :snapshot_number
  attributes :title, :description

  has_one :contributor
  has_many :people

  def self_link
    polymorphic_path([object.parent, object])
  end

  def download_link
    "#{self_link}/download"
  end

  def _links
    { self: self_link, download: download_link }
  end

end
