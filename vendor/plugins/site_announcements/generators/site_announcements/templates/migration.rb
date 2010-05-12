class SiteAnnouncementsMigration < ActiveRecord::Migration
  def self.up
    create_table :site_announcements do |t|
      t.column :announcer_id,:integer
      t.column :announcer_type,:string
      t.column :title, :string
      t.column :body,:text
      t.column :site_announcement_category_id,:integer
      t.column :is_headline,:boolean,:default=>false     
      t.column :expires_at,:datetime
      t.column :show_in_feed,:boolean,:default=>true
      t.column :email_notification,:boolean,:default=>false

      t.timestamps
    end

    create_table :site_announcement_categories do |t|
      t.column :title, :string
      t.column :icon_key,:string

      t.timestamps
    end
  end
  
  def self.down
    drop_table :site_announcements
    drop_table :site_announcement_categories
  end
end
