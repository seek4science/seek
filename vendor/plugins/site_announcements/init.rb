

ActionView::Base.send(:include, SiteAnnouncementsHelper)
ActiveRecord::Base.send(:include,SiteAnnouncements::Acts)

# FIX for engines model reloading issue in development mode
if ENV['RAILS_ENV'] != 'production'
	load_paths.each do |path|
		ActiveSupport::Dependencies.load_once_paths.delete(path)
	end
end


