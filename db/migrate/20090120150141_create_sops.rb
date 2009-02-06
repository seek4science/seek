class CreateSops < ActiveRecord::Migration
  def self.up
    create_table :sops do |t|
      t.column :contributor_type,  :string
      t.column :contributor_id,    :integer
      
      t.column :title,             :string
      t.column :description,       :text
      
      t.column :original_filename, :string
      t.column :content_type,      :string
      
      t.column :content_blob_id,   :integer
      
      t.timestamps
      t.column :last_used_at,      :datetime
    end
  end

  def self.down
    drop_table :sops
  end
end
