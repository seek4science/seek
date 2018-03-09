# SysMO: lib/authorization.rb
# Code taken from myExperiment and adopted for SysMO requirements.
# Greatly simplified 22/7/2010
# Greatlier simplified 24/10/2016
# **********************************************************************************
# * myExperiment: lib/is_authorized.rb
# *
# * Copyright (c) 2007 University of Manchester and the University of Southampton.
# * See license.txt for details.
# **********************************************************************************

module Seek
  module Permissions
    module Authorization
      # TO FUTURE REFACTORERS: Any changes to the method below (or to the methods that it calls) need to be reflected
      #   in the  batch update method `update_lookup_table_for_all_users` (lib/seek/permissions/policy_based_authorization.rb).
      #   If not, the auth table will not be accurate.
      def self.is_authorized?(action, thing, user = nil)
        authorized_as_creator?(action, thing, user) ||
          authorized_by_policy?(action, thing, user) ||
          authorized_by_permission?(action, thing, user) ||
          authorized_by_role?(action, thing, user)
      end

      def self.authorized_as_creator?(action, thing, user = nil)
        if user
          # Is the uploader?
          if thing.contributor && (thing.contributor == user || thing.contributor == user.person)
            return true
          # Is a creator?
          elsif thing.respond_to?(:creators) && user.person && thing.creators.include?(user.person) &&
                access_type_allows_action?(action, Policy::EDITING)
            return true
          end
        end

        false
      end

      def self.authorized_by_policy?(action, thing, user)
        # Check the user is "in scope" and also is performing an action allowed under the given access type
        if thing.policy.sharing_scope == Policy::ALL_USERS
          access_type_allows_action?(action, thing.policy.access_type) && !user.nil?
        else
          access_type_allows_action?(action, thing.policy.access_type)
        end
      end

      def self.authorized_by_permission?(action, thing, user = nil)
        if thing.policy.permissions.any? && user && user.person
          person = user.person

          thing.permission_for ||= {} # This is a little cache. Initialize it here.

          if thing.permission_for.key?(person) # Look-up in the cache first
            permission = thing.permission_for[person]
          else
            # Get a list of the policy's permissions, and sort by precedence
            permissions = Permission.sort_for(person, thing.policy.permissions)

            # Select only the permissions that relate to the user
            permission = permissions.detect { |p| p.controls_access_for?(person) }

            # Cache the permission (or lack thereof - could be nil)
            thing.permission_for[person] = permission
          end

          permission ? permission.allows_action?(action, person) : false
        else
          false
        end
      end

      def self.authorized_by_role?(action, thing, user = nil)
        return false if user.nil? || user.person.nil?

        if user.person.is_asset_housekeeper_of?(thing) && thing.asset_housekeeper_can_manage?
          access_type = Policy::MANAGING
        elsif user.person.is_asset_gatekeeper_of?(thing) && thing.asset_gatekeeper_can_publish?
          access_type = Policy::PUBLISHING
        else
          return false
        end

        access_type_allows_action?(action, access_type)
      end

      # checks if the "access_type" permits an action of a certain type (based on cascading permissions)
      def self.access_type_allows_action?(action, access_type)
        case action
        when 'view'
          access_type >= Policy::VISIBLE && access_type <= Policy::MANAGING
        when 'download'
          access_type >= Policy::ACCESSIBLE && access_type <= Policy::MANAGING
        when 'edit'
          access_type >= Policy::EDITING && access_type <= Policy::MANAGING
        when 'delete', 'manage'
          access_type == Policy::MANAGING
        when 'publish'
          access_type == Policy::PUBLISHING || access_type == Policy::MANAGING
        else
          false
        end
      end
    end
  end
end
