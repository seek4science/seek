#A placeholder for little hacks required to get various plugins working during the upgrade to rails 3
#these are items that will need revisiting
SEEK::Application.configure do

  #FIXME: having to do this suggests the gem init.rb isn't being invoked
  ActiveRecord::Base.send(:include,SiteAnnouncements::Acts)

  require_dependency File.join(Gem.loaded_specs['my_savage_beast'].full_gem_path,'app','models',"monitorship")

end
