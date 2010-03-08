require 'bioportal'

ActionView::Base.send(:include, BioPortal::BioPortalHelper)
ActiveRecord::Base.send(:include,BioPortal::Acts)
