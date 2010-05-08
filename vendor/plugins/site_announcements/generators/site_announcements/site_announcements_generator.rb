class SiteAnnouncementsGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.migration_template 'migration.rb', 'db/migrate', :migration_file_name => "site_announcements_migration"
    end
  end
end
