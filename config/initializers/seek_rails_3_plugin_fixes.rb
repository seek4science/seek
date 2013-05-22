#A placeholder for little hacks required to get various plugins working during the upgrade to rails 3
#these are items that will need revisiting

require 'redbox_helper'

SEEK::Application.configure do

  ActionView::Base.send :include, WhiteListHelper

  require_dependency File.join(Gem.loaded_specs['my_savage_beast'].full_gem_path,'app','models',"monitorship")
  require_dependency File.join(Gem.loaded_specs['my_savage_beast'].full_gem_path,'app','models',"moderatorship")
  require_dependency File.join(Gem.loaded_specs['my_savage_beast'].full_gem_path,'app','models',"posts_sweeper")

  require_dependency File.join(Gem.loaded_specs['my_savage_beast'].full_gem_path,'app','controllers',"forums_controller")


  ActionView::Base.send(:include, RedboxHelper)
end
