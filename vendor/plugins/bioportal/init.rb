require 'bioportal'
require 'bio_portal_helper'
require 'app/models/bioportal_concept'

ActionView::Base.send(:include, BioPortal::BioPortalHelper)
ActiveRecord::Base.send(:include,BioPortal::Acts)
