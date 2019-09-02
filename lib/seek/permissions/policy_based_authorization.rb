module Seek
  module Permissions
    module PolicyBasedAuthorization
      def self.included(klass)
        attr_accessor :permission_for
        klass.extend AuthLookupClassMethods
        klass.class_eval do
          belongs_to :contributor, class_name: 'Person' unless method_defined? :contributor
          after_initialize :contributor_or_default_if_new

          # checks a policy exists, and if missing resorts to using a private policy
          after_initialize :policy_or_default_if_new

          include Seek::ProjectAssociation unless method_defined? :projects

          belongs_to :policy, autosave: true
          enforce_required_access_for_owner :policy, :manage

          after_commit :check_to_queue_update_auth_table
          after_destroy { |record| record.policy.try(:destroy_if_redundant) }

          const_set('AuthLookup', Class.new(::AuthLookup)).class_eval do |c|
            c.table_name = klass.lookup_table_name
            belongs_to :asset, class_name: klass.name, inverse_of: :auth_lookup
          end

          has_many :auth_lookup, foreign_key: :asset_id, inverse_of: :asset, dependent: :delete_all
        end
      end
      # the can_#{action}? methods are split into 2 parts, to differentiate between pure authorization and additional permissions based upon the state of the object or other objects it depends upon)
      # for example, an assay may not be deleted if it is linked to assets, even though the authorization of the user wishing to do so allows it - meaning the authorization passes, but its current state does not
      # therefore the can_#{action} depends upon 2 pairs of methods returning true:
      # - authorized_for_#{action}? - to check that the user specified is actually authorized to carry out that action on the item
      # - state_allows_#{action} - to chekc that the state of the object allows that action to proceed
      #
      # by default state_allows_#{action} always returns true, but can be overridden in the particular model type to tune its behaviour
      Seek::Permissions::ActsAsAuthorized::AUTHORIZATION_ACTIONS.each do |action|
        eval <<-END_EVAL
            def can_#{action}? user = User.current_user
              authorized_for_#{action}?(user) && state_allows_#{action}?(user)
            end

            def authorized_for_#{action}? user = User.current_user
                return true if new_record?
                user_id = user.nil? ? 0 : user.id
                if Seek::Config.auth_lookup_enabled
                  lookup = self.lookup_for("#{action}", user_id)
                else
                  lookup=nil
                end
                if lookup.nil?
                  authorized_for_action(user,"#{action}")
                else
                  lookup
                end
            end
        END_EVAL
      end

      module AuthLookupArrayExtensions
        # Allows an Enumerable to be authorized in the same way as an ActiveRecord model or relation.
        def all_authorized_for(action, user = User.current_user, filter_by_permissions = true)
          x = select { |a| a.send("authorized_for_#{action}?", user) }
          x = x.select { |a| a.send("state_allows_#{action}?", user) } if filter_by_permissions
          x
        end
      end

      module AuthLookupClassMethods
        # authorizes the current relation for a given action and optionally a user. If user is nil, the items authorised for an
        # anonymous user are returned. if filter_by_permissions is true, then as well as the authorization the state based permissions will also be applied
        def all_authorized_for(action, user = User.current_user, filter_by_permissions = true)
          user_id = user&.id || 0
          if Seek::Config.auth_lookup_enabled && lookup_table_consistent?(user_id)
            assets = lookup_join(action, user_id)
          else
            assets = all.to_a.all_authorized_for(action, user, false)
          end

          if filter_by_permissions && should_check_state?(action)
            assets = assets.select { |a| a.send("state_allows_#{action}?", user) }
          end

          assets
        end

        # returns the authorised items from the array of the same class items for a given action and optionally a user. If user is nil, the items authorised for an
        # anonymous user are returned. All assets must be of the same type and match the asset class this method was called on
        # if filter_by_permissions is true, then as well as the authorization the state based permissions will also be applied
        def authorize_asset_collection(assets, action, user = User.current_user, filter_by_permissions = true)
          return assets if assets.empty?
          user_id = user&.id || 0
          if Seek::Config.auth_lookup_enabled && lookup_table_consistent?(user_id) && !assets.is_a?(ActiveRecord::Relation)
            ids = lookup_class.select(:asset_id).where(asset_id: assets.collect(&:id), user_id: user_id, "can_#{action}" => true).pluck(:asset_id)
            assets = assets.select { |asset| ids.include?(asset.id.to_s) }
          else
            assets = assets.all_authorized_for(action, user, false)
          end

          if filter_by_permissions && should_check_state?(action)
            assets = assets.select { |a| a.send("state_allows_#{action}?", user) }
          end

          assets
        end

        # Only check `state_allows...` if it has been overridden.
        def should_check_state?(action)
          instance_method("state_allows_#{action}?").owner != Seek::Permissions::StateBasedPermissions
        end

        # deletes entries where the ID doesn't match that of an existing ID
        def remove_invalid_auth_lookup_entries
          lookup_class.where('asset_id NOT IN (?)', pluck(:id)).delete_all
        end

        # determines whether the lookup table records are consistent with the number of asset items in the database and the last id of the item added
        #  if it isn't consistent it will automatically remove entries that do no match the id of an existing asset of the type (calling #remove_invalid_auth_lookup_entries)
        def lookup_table_consistent?(user_id)
          user_id = user_id.nil? ? 0 : user_id.id unless user_id.is_a?(Numeric)
          # cannot rely purely on the count, since an item could have been deleted and a new one added
          lookup_count = lookup_count_for_user(user_id)
          last_lookup_asset_id = last_asset_id_for_user(user_id)
          last_id = unscoped.maximum(:id)
          asset_count = unscoped.count

          # trigger off a full update for that user if the count is zero and items should exist for that type
          if lookup_count == 0 && !last_id.nil?
            AuthLookupUpdateJob.new.add_items_to_queue User.find_by_id(user_id)
          end

          (lookup_count == asset_count && (asset_count == 0 || (last_lookup_asset_id == last_id)))
        end

        # the name of the lookup table, holding authorisation lookup information, for this given authorised type
        def lookup_table_name
          "#{table_name.singularize}_auth_lookup" # Changed to handle namespaced models e.g. TavernaPlayer::Run
        end

        def lookup_class
          const_get("#{name}::AuthLookup")
        end

        # removes all entries from the authorization lookup type for this authorized type
        def clear_lookup_table
          lookup_class.delete_all
        end

        # the record count for entries within the authorization lookup table for a given user_id or user. Used to determine if the table is complete
        def lookup_count_for_user(user)
          lookup_class.where(user_id: user || 0).count
        end

        def lookup_join(action, user)
          joins(:auth_lookup).where(lookup_table_name => { user_id: user, "can_#{action}" => true })
        end

        # the highest asset id recorded in authorization lookup table for a given user_id or user. Used to determine if the table is complete
        def last_asset_id_for_user(user_id)
          lookup_class.where(user_id: user_id || 0).maximum(:asset_id) || -1
        end
      end

      # allows access to each permission in a single database call (rather than calling can_download? can_edit? etc individually)
      def authorization_permissions(user = User.current_user)
        user_id = user&.id || 0
        if Seek::Config.auth_lookup_enabled && self.class.lookup_table_consistent?(user_id)
          permissions = auth_lookup.where(user_id: user).first
          if permissions.nil?
            raise 'Expected to find record in auth lookup table'
          else
            permissions
          end
        else
          permissions = auth_lookup.build
          AuthLookup::ABILITIES.each do |a|
            permissions.send("can_#{a}=", send("can_#{a}?"))
          end
          permissions
        end
      end

      # triggers a background task to update or create the authorization lookup table records for this item
      def check_to_queue_update_auth_table
        return if destroyed?
        if try(:creators_changed?) || (previous_changes.keys & %w[contributor_id owner_id]).any?
          AuthLookupUpdateJob.new.add_items_to_queue self
        end
      end

      # updates or creates the authorization lookup entries for this item and the provided user (nil indicating anonymous user)
      def update_lookup_table(user = nil)
        user_id = user.nil? ? 0 : user.id
        auth_lookup.where(user_id: user_id).delete_all

        params = { user_id: user_id }
        AuthLookup::ABILITIES.each { |a| params["can_#{a}"] = authorized_for_action(user, a) }
        auth_lookup.create!(params)
      end

      def update_lookup_table_for_all_users
        # Blank-out permissions first

        # 1 entry for each user + anonymous
        if auth_lookup.count != (User.count + 1)
          auth_lookup.wipe
        else
          auth_lookup.batch_update([false, false, false, false, false])
        end

        # Specific permissions (Permission)

        # Sort permissions according to precedence, then access type, so the most direct (People), permissive (Manage)
        # permissions are applied last.
        sorted_permissions = policy.permissions
                                 .sort_by { |p| -(Permission::PRECEDENCE.index(p.contributor_type) * 100 - p.access_type) }

        # Extract the individual member permissions from each FavouriteGroup and ensure they are also sorted by access_type:
        # 1. Record the index where the FavouriteGroup permissions start
        fav_group_perm_index = sorted_permissions.index { |p| p.contributor_type == 'FavouriteGroup' }
        if fav_group_perm_index
          # 2. Split them out of the array.
          group_permissions, sorted_permissions = sorted_permissions.partition { |p| p.contributor_type == 'FavouriteGroup' }

          # 3. Gather the FavouriteGroupMemberships for each of the FavouriteGroups referenced by the permissions.
          group_members_permissions = FavouriteGroupMembership.includes(person: :user)
                                          .where(favourite_group_id: group_permissions.map(&:contributor_id))
                                          .order('access_type ASC').to_a

          # 4. Add them in to the array at the point where the FavouriteGroup permissions were removed
          #    to preserve the order of precedence.
          sorted_permissions.insert(fav_group_perm_index, *group_members_permissions)
        end

        # Update the lookup for each permission
        sorted_permissions.each do |permission|
          auth_lookup.where(user_id: permission.affected_people.map(&:user)).batch_update(permission)
        end

        # Creator permissions
        if respond_to?(:creators) && creators.any?
          auth_lookup.where(user_id: creators.includes(:user).map(&:user).compact).batch_update([true, true, true, false, false], false)
        end

        # Contributor permissions
        if contributor && contributor.user
          auth_lookup.where(user_id: contributor.user).batch_update([true, true, true, true, true])
        end

        # Role permissions (Role)
        if asset_housekeeper_can_manage?
          asset_housekeepers = projects.map(&:asset_housekeepers).flatten.map(&:user).compact
          if asset_housekeepers.any?
            auth_lookup.where(user_id: asset_housekeepers).batch_update([true, true, true, true, true])
          end
        end

        # Global permissions (Policy)
        auth_lookup.batch_update(policy,  false)

        # block from anonymous users if policy is shared with ALL_USERS only
        auth_lookup.where(user_id: 0).batch_update([false, false, false, false, false]) if policy.sharing_scope == Policy::ALL_USERS
      end

      def contributor_credited?
        !respond_to?(:creators) || creators.empty?
      end

      # item is accessible to members of the projects passed. Ignores additional restrictions, such as additional permissions to block particular members.
      # if items is a downloadable it needs to be ACCESSIBLE, otherwise just VISIBLE
      def projects_accessible?(projects)
        policy.projects_accessible?(projects, self.is_downloadable?)
      end

      delegate :private?, to: :policy
      delegate :public?, to: :policy

      def default_policy
        Policy.default
      end

      def policy_or_default_if_new
        self.policy = default_policy if new_record? && !policy
      end

      def default_contributor
        User.current_user.try(:person)
      end

      def has_advanced_permissions?
        # Project permissions don't count as "advanced"
        (policy.permissions.collect(&:contributor) - projects).any?
      end

      def contributor_or_default_if_new
        if new_record? && contributor.nil?
          self.contributor = default_contributor
        end
      end

      # use request_permission_summary to retrieve who can manage the item
      def people_can_manage
        contributor = self.contributor
        return [[contributor.id, "#{contributor.first_name} #{contributor.last_name}", Policy::MANAGING]] if policy.blank?
        creators = is_downloadable? ? self.creators : []
        asset_managers = (projects & contributor.former_projects).collect(&:asset_housekeepers).flatten
        grouped_people_by_access_type = policy.summarize_permissions creators, asset_managers, contributor
        grouped_people_by_access_type[Policy::MANAGING]
      end

      def authorized_for_action(user, action)
        Authorization.is_authorized?(action, self, user)
      end

      # returns a list of the people that can manage this file
      # which will be the contributor, and those that have manage permissions
      def managers
        people = []

        people << contributor unless contributor.nil?

        perms = policy.permissions.where(access_type:Policy::MANAGING, contributor_type:'Person').select{|p| p.contributor}
        people |= perms.collect(&:contributor)
        people.uniq
      end

      def contributing_user
        contributor.try(:user)
      end

      # members of project can see some information of hidden items of their project
      def can_see_hidden_item?(person)
        person.member_of?(projects)
      end

      # Check if ALL the managers of the items are no longer involved with ANY of the item's projects
      def asset_housekeeper_can_manage?
        managers.map { |manager| (projects - manager.person.former_projects).none? }.all?
      end

      def contributors
        Person.where(id: contributor_ids)
      end

      def contributor_ids
        ids = [contributor_id]
        ids += versions.pluck(:contributor_id) if self.respond_to?(:versions)
        ids.uniq
      end

      # looks up the entry in the authorization lookup table for a single authorised type, for a given action, user_id and asset_id. A user id of zero
      # indicates an anonymous user. Returns nil if there is no record available
      def lookup_for(action, user_id)
        auth_lookup.where(user_id: user_id).limit(1).pluck("can_#{action}").first
      end
    end
  end
end
