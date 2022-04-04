# BioCatalogue: app/helpers/api_helper.rb
#
# Copyright (c) 2008-2009, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.
require 'jbuilder'
require 'jbuilder/json_api/version'
module ApiHelper

  # Used by JSON serializer
  def avatar_href_link(object)
    uri = nil
    uri = "/#{object.class.name.pluralize.underscore}/#{object.id}/avatars/#{object.avatar.id}" unless object.avatar.nil?
    uri
  end

  # Used by JSON serializer
  def determine_submitter(object)
    # FIXME: needs to be the creators for assets
    return object.owner if object.respond_to?('owner')
    result = object.contributor if object.respond_to?('contributor') && !object.is_a?(Permission)
    if result
      return result if result.instance_of?(Person)
      return result.person if result.instance_of?(User)
    end

    nil
  end


end
