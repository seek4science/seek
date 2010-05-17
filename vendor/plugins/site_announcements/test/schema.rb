ActiveRecord::Schema.define(:version => 0) do
  create_table "site_announcement_categories", :force => true do |t|
    t.string   "title"
    t.string   "icon_key"
    t.datetime "created_at"
    t.datetime "updated_at"
  end
  
  create_table "site_announcements", :force => true do |t|
    t.integer  "announcer_id"
    t.string   "announcer_type"
    t.string   "title"
    t.text     "body"
    t.integer  "site_announcement_category_id"
    t.boolean  "is_headline",                   :default => false
    t.datetime "expires_at"
    t.boolean  "show_in_feed",                  :default => true
    t.boolean  "email_notification",            :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end
  
  create_table "notifiee_infos", :force=>true do |t|
    t.column :notifiee_id,:integer
    t.column :notifiee_type,:string
    t.column :unique_key,:string
    t.column :receive_notifications,:boolean,:default=>true
        
    t.timestamps
  end
end
