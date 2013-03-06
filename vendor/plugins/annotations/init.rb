require File.join(File.dirname(__FILE__), "lib", "annotations")

# FIX for engines model reloading issue in development mode
if ENV['RAILS_ENV'] != 'production'
	load_paths.each do |path|
		ActiveSupport::Dependencies.autoload_once_paths.delete(path)
	end
end
