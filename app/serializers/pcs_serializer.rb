#PCS = policy, creator, submitter.
#FIX ME: Policy was removed from readAPI, then re-added elsewhere per request. check if it can be put back here.
class PCSSerializer < BaseSerializer

  attribute :snapshots do
    snapshots_data = []
    object.snapshots.each do |v|
      path = polymorphic_path([object, v])
      snapshots_data.append(snapshot: v.snapshot_number,
                            url: "#{base_url}#{path}")
    end
    snapshots_data
  end


  has_many :creators
  has_many :submitter # set seems to be one way of doing optional
end
