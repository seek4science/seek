class SnapshottableSerializer  < BaseSerializer

  has_many :creators
  has_many :submitter

  attribute :snapshots do
    snapshots_data = []
    object.snapshots.each do |v|
      url = polymorphic_url([object, v])
      snapshots_data.append(snapshot: v.snapshot_number,
                            url: url)
    end
    snapshots_data
  end


end