class SnapshottableSerializer  < PCSSerializer

  attribute :snapshots do
    snapshots_data = []
    object.snapshots.each do |v|
      path = polymorphic_path([object, v])
      snapshots_data.append(snapshot: v.snapshot_number,
                            url: "#{base_url}#{path}")
    end
    snapshots_data
  end


end