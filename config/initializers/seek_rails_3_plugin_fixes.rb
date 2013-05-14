#A placeholder for little hacks required to get various plugins working during the upgrade to rails 3
#these are items that will need revisiting
require 'bioportal'
require 'pubmed_record'

SEEK::Application.configure do

  require_dependency File.join(Gem.loaded_specs['my_savage_beast'].full_gem_path,'app','models',"monitorship")
  require_dependency File.join(Gem.loaded_specs['my_savage_beast'].full_gem_path,'app','models',"moderatorship")
  require_dependency File.join(Gem.loaded_specs['my_savage_beast'].full_gem_path,'app','models',"posts_sweeper")

  require_dependency File.join(Gem.loaded_specs['my_savage_beast'].full_gem_path,'app','models',"posts_sweeper")

  require_dependency File.join(Gem.loaded_specs['bioportal'].full_gem_path,'app','helpers',"bio_portal_helper")
  require_dependency File.join(Gem.loaded_specs['bioportal'].full_gem_path,'app','models',"bioportal_concept")
  #ActionView::Base.send(:include, BioPortal::BioPortalHelper)
  ActiveRecord::Base.send(:include,BioPortal::Acts)
end
