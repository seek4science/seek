class RemoveScales < ActiveRecord::Migration[6.1]
  def change
    drop_table 'scales' do |t|
      t.string 'title'
      t.string 'key'
      t.integer 'pos', default: 1
      t.string 'image_name'
      t.timestamps
    end

    drop_table 'scalings' do |t|
      t.integer 'scale_id'
      t.integer 'scalable_id'
      t.integer 'person_id'
      t.string 'scalable_type'
      t.timestamps
    end
  end
end
