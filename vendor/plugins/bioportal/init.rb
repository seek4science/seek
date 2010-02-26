require 'bioportal'
require 'bio_portal_helper'

ActionView::Base.send(:include, BioPortal::BioPortalHelper)
ActiveRecord::Base.send(:include,BioPortal::Acts)
