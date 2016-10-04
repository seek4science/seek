# SysMO: lib/authorization.rb
# Code taken from myExperiment and adopted for SysMO requirements.
# Greatly simplified 22/7/2010
# **********************************************************************************
# * myExperiment: lib/is_authorized.rb
# *
# * Copyright (c) 2007 University of Manchester and the University of Southampton.
# * See license.txt for details.
# **********************************************************************************

module Seek

  module Permissions

    module Authorization

      def self.is_authorized?(action, thing, user=nil)
        is_authorized_as_creator?(action, thing, user) ||
            is_authorized_by_policy?(action, thing) ||
            is_authorized_by_permission?(action, thing, user)
      end

      private

      def self.is_authorized_as_creator?(action, thing, user = nil)
        if user
          # Is the uploader?
          if thing.contributor == user || thing.contributor == user.person
            return true #contributor is always authorized
            # Is a creator?
          elsif thing.is_downloadable? && thing.creators.include?(user.person) && access_type_allows_action?(action, Policy::EDITING)
            return true
          end
        end

        false
      end

      def self.is_authorized_by_policy?(action, thing)
        # Check the user is "in scope" and also is performing an action allowed under the given access type
        access_type_allows_action?(action, thing.policy.access_type)
      end

      def self.is_authorized_by_permission?(action, thing, user = nil)
        if thing.policy.permissions.any? && user
          # == CUSTOM PERMISSIONS
          # 1. Check if there is a specific permission relating to the user
          # 2. Check if there is a permission for a FavouriteGroup they're in
          # 3. Check if there is a permission for their project
          # 4. Check the action is allowed by the access_type of the permission
          person = user.person

          thing.permission_for ||= {} # This is a little cache. Initialize it here.

          if thing.permission_for.key?(person) # Look-up in the cache first
            permission = thing.permission_for[person]
          else
            # sort permissions by precedence
            permissions = Permission.sort_for(person, thing.policy.permissions)
            # find the first permission, which actually overrides the permission
            # later in that same list. E.g. a person permission will override
            # a project permission

            permission = permissions.detect { |p| p.controls_access_for? user.person }

            # Cache the permission (or lack thereof - could be nil)
            thing.permission_for[person] = permission
          end

          permission ? permission.allows_action?(action, user.person) : false
        end
      end

      # checks if the "access_type" permits an action of a certain type (based on cascading permissions)
      def self.access_type_allows_action?(action, access_type)
        case action
          when "view"
            return access_type >= Policy::VISIBLE
          when "download"
            return access_type >= Policy::ACCESSIBLE
          when "edit"
            return access_type >= Policy::EDITING
          when "delete"
            return access_type >= Policy::MANAGING
          when "manage"
            return access_type >= Policy::MANAGING
          else
            # any other type of action is not allowed by permissions
            return false
        end
      end
    end
  end
end
