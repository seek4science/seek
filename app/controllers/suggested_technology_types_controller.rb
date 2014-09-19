class SuggestedTechnologyTypesController < ApplicationController
  include Seek::Ontologies::SuggestedTypeHandler
  before_filter :check_allowed_to_manage_types, :only => [:destroy, :manage]

  before_filter :project_membership_required_appended, :only => [:manage]
  before_filter :find_and_authorize_requested_item, :only => [:edit, :destroy]

end
