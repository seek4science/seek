class RemovePersonResponsible < ActiveRecord::Migration
  def self.up
    execute("SELECT id, person_responsible_id FROM studies").each do |id|
      study_id = id[0]
      person_responsible_id = id[1]
      if person_responsible_id
        assets_creators = execute("SELECT * FROM assets_creators WHERE asset_type='Study' AND asset_id=#{study_id} AND creator_id=#{person_responsible_id}")
        if assets_creators.first.nil?
          raise  Exception.new("Please make sure person_responsible_id is copied before removed! try rake task seek:move_person_responsible_to_creator")
        end
      end
    end

    remove_column :studies,:person_responsible_id
  end

  def self.down
    add_column :studies,:person_responsible_id,:integer
  end
end
