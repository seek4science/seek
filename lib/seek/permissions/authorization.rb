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

      def self.authorization_supported? thing
        !thing.nil? && thing.authorization_supported?
      end


      # 1) action_name - name of the action that is about to happen with the "thing"
      # 2) thing_type - this parameter is deprecated
      # 3) thing - instance of resource to be authorized
      # 4) user - instance of user
      def self.is_authorized?(action, thing_type, thing, user=nil)

        # initially not authorized, so if all tests fail -
        # safe result of being not authorized will get returned
        is_authorized = false

        policy = thing.policy

        # == BASIC POLICY
        # 1. Check the user's "scope" level, to match the sharing scopes defined in policy.
        # 2. If they're in "scope", check the action they're trying to perform is allowed by the access_type
        scope = nil
        if user.nil?
          scope = Policy::EVERYONE
        else
          if thing.contributor == user || thing.contributor == user.person #Warning to future refactorers, this would pass in the case that
                                                                           #  the user was nil (not logged in) and the contributor was also nil (jerm resource)
                                                                           #  IF we didn't already check for a nil user above.
            scope = Policy::PRIVATE
            return true #contributor is always authorized
                                                                           # have to do this because of inconsistancies with access_type that mess up later on
                                                                           # (4 = can manage, 0 = can manage... if contributor) ???
          elsif thing.is_downloadable? and thing.creators.include?(user.person) and access_type_allows_action?(action, Policy::EDITING)
            scope = Policy::PRIVATE
            return true
          else
            if user.person && user.person.projects.empty?
              scope = Policy::EVERYONE
            else
              scope = Policy::ALL_USERS
            end
          end
        end
        # Check the user is "in scope" and also is performing an action allowed under the given access type
        is_authorized = (scope <= policy.sharing_scope &&
            access_type_allows_action?(action, policy.access_type))

        # == END BASIC POLICY
        if policy.permissions.any? && user
          # == CUSTOM PERMISSIONS
          # 1. Check if there is a specific permission relating to the user
          # 2. Check if there is a permission for a FavouriteGroup they're in
          # 3. Check if there is a permission for their project
          # 4. Check the action is allowed by the access_type of the permission
          person = user.person
          thing.permission_for ||= {}   # if thing.permission_for is defined,
                                        # nothing happens, otherwise empty hash
          p = thing.permission_for[person]
          permission = if p

                         p == :nil ? nil : p  # distinguish empty hash item from item with value :nil
                       else
                         # sort permissions by precedence
                         permissions = Permission.sort_for(person, policy.permissions)
                         # find the first permission, which actually overrides the permission
                         # later in that same list. E.g. a person permission will override
                         # a project permission

                         #strip out the more restrictive persmissions if overall scope is EVERYONE
                         if policy.sharing_scope==Policy::EVERYONE
                           permissions.reject!{|permission| permission.access_type <= policy.access_type}
                         end

                         permission = permissions.detect { |p| p.controls_access_for? user.person }
                         # turn nil into :nil, so that caching is possible
                         permission ? thing.permission_for[person] = permission : thing.permission_for[person] = :nil
                         # return the resulting value
                         permission
                       end

          # now find out if the resulting permissions suffice
          is_authorized = permission.allows_action? action, user.person if permission
          # == END CUSTOM PERMISSIONS
        end

        # == BLACK/WHITE LISTS
        # 1. Check if they're in the whitelist
        # 2. Check if they're not in the blacklist (overrules whitelist)
        contributor = thing.contributor
        contributor = contributor.user if contributor.respond_to? :user
        if contributor && user
          # == WHITE LIST
          if policy.use_whitelist && contributor.get_whitelist
            is_authorized = true if is_person_in_whitelist?(user.person, contributor) && access_type_allows_action?(action, FavouriteGroup::WHITELIST_ACCESS_TYPE)
          end
          # == END WHITE LIST
          # == BLACK LIST
          if policy.use_blacklist && contributor.get_blacklist
            is_authorized = false if is_person_in_blacklist?(user.person, contributor)
          end
          # == END BLACK LIST
        end
        # == END BLACK/WHITE LISTS

        return is_authorized
      end

      private

      # checks if a person belongs to a blacklist of a particular user
      def self.is_person_in_blacklist?(person, blacklist_owner)
        return blacklist_owner.get_blacklist.people.include?(person)
      end

      # checks if a person belongs to a whitelist of a particular user
      def self.is_person_in_whitelist?(person, whitelist_owner)
        return whitelist_owner.get_whitelist.people.include?(person)
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
