module Seek
  module Permissions
    module PolicyBasedAuthorization
      class AuthPermissions < Struct.new :can_view, :can_download, :can_edit, :can_manage, :can_delete
      end

      def self.included(klass)
        attr_accessor :permission_for
        klass.extend AuthLookupClassMethods
        klass.class_eval do
          belongs_to :contributor, polymorphic: true unless method_defined? :contributor
          after_initialize :contributor_or_default_if_new

          # checks a policy exists, and if missing resorts to using a private policy
          after_initialize :policy_or_default_if_new

          include Seek::ProjectAssociation unless method_defined? :projects

          belongs_to :policy, autosave: true
          enforce_required_access_for_owner :policy, :manage

          after_commit :check_to_queue_update_auth_table
          after_destroy :remove_from_lookup_table
          after_destroy { |record| record.policy.try(:destroy_if_redundant) }
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
                  lookup = self.class.lookup_for_asset("#{action}", user_id,self.id)
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

      module AuthLookupClassMethods
        # returns all the authorised items for a given action and optionally a user and set of projects. If user is nil, the items authorised for an
        # anonymous user are returned. If one or more projects are provided, then only the assets linked to those projects are included.
        # if filter_by_permissions is true, then as well as the authorization the state based permissions will also be applied
        def all_authorized_for(action, user = User.current_user, projects = nil, filter_by_permissions = true)
          projects = Array(projects) unless projects.nil?
          user_id = user.nil? ? 0 : user.id
          assets = []
          programatic_project_filter = !projects.nil? && (!Seek::Config.auth_lookup_enabled || (self == Assay || self == Study))
          if Seek::Config.auth_lookup_enabled
            if lookup_table_consistent?(user_id)
              Rails.logger.info("Lookup table #{lookup_table_name} is complete for user_id = #{user_id}")
              assets = lookup_for_action_and_user action, user_id, projects
            else
              Rails.logger.info("Lookup table #{lookup_table_name} is incomplete for user_id = #{user_id} - doing things the slow way")
              assets = default_order.select { |df| df.send("authorized_for_#{action}?", user) }
              programatic_project_filter = !projects.nil?
            end
          else
            assets = default_order.select { |df| df.send("authorized_for_#{action}?", user) }
          end

          if filter_by_permissions
            assets = assets.select { |a| a.send("state_allows_#{action}?", user) }
          end

          if programatic_project_filter
            assets.reject { |a| (a.projects & projects).empty? }
          else
            assets
          end
        end

        # returns the authorised items from the array of the same class items for a given action and optionally a user. If user is nil, the items authorised for an
        # anonymous user are returned. All assets must be of the same type and match the asset class this method was called on
        # if filter_by_permissions is true, then as well as the authorization the state based permissions will also be applied
        def authorize_asset_collection(assets, action, user = User.current_user, filter_by_permissions = true)
          return assets if assets.empty?
          user_id = user.nil? ? 0 : user.id
          if Seek::Config.auth_lookup_enabled && lookup_table_consistent?(user_id)
            ids = assets.collect(&:id)
            clause = "asset_id IN (#{ids.join(',')})"
            sql =  "SELECT asset_id from #{lookup_table_name} WHERE user_id = #{user_id} AND (#{clause}) AND can_#{action}=#{ActiveRecord::Base.connection.quoted_true}"
            ids = ActiveRecord::Base.connection.select_all(sql).collect { |k| k['asset_id'].to_s }
            assets = assets.select { |asset| ids.include?(asset.id.to_s) }
          else
            assets = assets.select { |a| a.send("authorized_for_#{action}?", user) }
          end
          if filter_by_permissions
            assets = assets.select { |a| a.send("state_allows_#{action}?", user) }
          end
          assets
        end

        # determines whether the lookup table records are consistent with the number of asset items in the database and the last id of the item added
        def lookup_table_consistent?(user_id)
          user_id = user_id.nil? ? 0 : user_id.id unless user_id.is_a?(Numeric)
          # cannot rely purely on the count, since an item could have been deleted and a new one added
          c = lookup_count_for_user user_id
          last_stored_asset_id = last_asset_id_for_user user_id
          last_asset_id = unscoped.order(:id).last.try(:id)

          # trigger off a full update for that user if the count is zero and items should exist for that type
          if c == 0 && !last_asset_id.nil?
            AuthLookupUpdateJob.new.add_items_to_queue User.find_by_id(user_id)
          end
          c == count && (count == 0 || (last_stored_asset_id == last_asset_id))
        end

        # the name of the lookup table, holding authorisation lookup information, for this given authorised type
        def lookup_table_name
          "#{table_name.singularize}_auth_lookup" # Changed to handle namespaced models e.g. TavernaPlayer::Run
        end

        # removes all entries from the authorization lookup type for this authorized type
        def clear_lookup_table
          ActiveRecord::Base.connection.execute("delete from #{lookup_table_name}")
        end

        # the record count for entries within the authorization lookup table for a given user_id or user. Used to determine if the table is complete
        def lookup_count_for_user(user_id)
          user_id = user_id.nil? ? 0 : user_id.id unless user_id.is_a?(Numeric)
          sql = "select count(*) from #{lookup_table_name} where user_id = #{user_id}"
          ActiveRecord::Base.connection.select_one(sql).values[0].to_i
        end

        def lookup_for_action_and_user(action, user_id, projects)
          # Study's and Assays have to be treated differently, as they are linked to a project through the investigation'
          if projects.nil? || (self == Study || self == Assay)
            sql = "select asset_id from #{lookup_table_name} where user_id = #{user_id} and can_#{action}=#{ActiveRecord::Base.connection.quoted_true}"
            ids = ActiveRecord::Base.connection.select_all(sql).collect { |k| k['asset_id'] }
          else
            project_map_table = [name.underscore.pluralize.to_s, 'projects'].sort.join('_')
            project_map_asset_id = "#{name.underscore}_id"
            project_clause = projects.collect { |p| "#{project_map_table}.project_id = #{p.id}" }.join(' or ')
            sql = "select asset_id,#{project_map_asset_id} from #{lookup_table_name}"
            sql << " inner join #{project_map_table}"
            sql << " on #{lookup_table_name}.asset_id = #{project_map_table}.#{project_map_asset_id}"
            sql << " where #{lookup_table_name}.user_id = #{user_id} and (#{project_clause})"
            sql << " and can_#{action}=#{ActiveRecord::Base.connection.quoted_true}"
            ids = ActiveRecord::Base.connection.select_all(sql).collect { |k| k['asset_id'] }
          end
          default_order.where(id: ids)
        end

        # the highest asset id recorded in authorization lookup table for a given user_id or user. Used to determine if the table is complete
        def last_asset_id_for_user(user_id)
          user_id = user_id.nil? ? 0 : user_id.id unless user_id.is_a?(Numeric)
          v = ActiveRecord::Base.connection.select_one("select max(asset_id) from #{lookup_table_name} where user_id = #{user_id}").values[0]
          v.nil? ? -1 : v.to_i
        end

        # looks up the entry in the authorization lookup table for a single authorised type, for a given action, user_id and asset_id. A user id of zero
        # indicates an anonymous user. Returns nil if there is no record available
        def lookup_for_asset(action, user_id, asset_id)
          attribute = "can_#{action}"
          @@expected_true_value ||= ActiveRecord::Base.connection.quoted_true.delete("'")
          res = ActiveRecord::Base.connection.select_one("select #{attribute} from #{lookup_table_name} where user_id=#{user_id} and asset_id=#{asset_id}")
          if res.nil?
            nil
          else
            res[attribute].to_s == @@expected_true_value
          end
        end
      end

      # removes all entries related to this item from the authorization lookup table
      def remove_from_lookup_table
        id = self.id
        ActiveRecord::Base.connection.execute("delete from #{self.class.lookup_table_name} where asset_id=#{id}")
      end

      # allows access to each permission in a single database call (rather than calling can_download? can_edit? etc individually)
      def authorization_permissions(user = User.current_user)
        @@expected_true_value ||= ActiveRecord::Base.connection.quoted_true.delete("'")
        permissions = AuthPermissions.new
        user_id = user.nil? ? 0 : user.id
        if Seek::Config.auth_lookup_enabled && self.class.lookup_table_consistent?(user_id)
          sql = "SELECT can_view,can_edit,can_download,can_manage,can_delete FROM #{self.class.lookup_table_name} WHERE user_id=#{user_id} AND asset_id=#{id}"
          res = ActiveRecord::Base.connection.select_one(sql)
          if res.nil?
            raise 'Expected to find record in auth lookup table'
          else
            permissions.can_view = res['can_view'].to_s == @@expected_true_value && state_allows_manage?(user)
            permissions.can_download = res['can_download'].to_s == @@expected_true_value && state_allows_manage?(user)
            permissions.can_edit = res['can_edit'].to_s == @@expected_true_value && state_allows_manage?(user)
            permissions.can_manage = res['can_manage'].to_s == @@expected_true_value && state_allows_manage?(user)
            permissions.can_delete = res['can_delete'].to_s == @@expected_true_value && state_allows_manage?(user)
          end
        else
          permissions.can_view = can_view?
          permissions.can_download = can_download?
          permissions.can_edit = can_edit?
          permissions.can_manage = can_manage?
          permissions.can_delete = can_delete?
      end
        permissions
      end

      # triggers a background task to update or create the authorization lookup table records for this item
      def check_to_queue_update_auth_table
        unless (previous_changes.keys & %w[contributor_id owner_id]).empty?
          AuthLookupUpdateJob.new.add_items_to_queue self
        end
      end

      # updates or creates the authorization lookup entries for this item and the provided user (nil indicating anonymous user)
      def update_lookup_table(user = nil)
        self.class.transaction do
          user_id = user.nil? ? 0 : user.id

          can_view = ActiveRecord::Base.connection.quote authorized_for_action(user, 'view')
          can_edit = ActiveRecord::Base.connection.quote authorized_for_action(user, 'edit')
          can_download = ActiveRecord::Base.connection.quote authorized_for_action(user, 'download')
          can_manage = ActiveRecord::Base.connection.quote authorized_for_action(user, 'manage')
          can_delete = ActiveRecord::Base.connection.quote authorized_for_action(user, 'delete')

          # check to see if an insert of update is needed, action used is arbitary
          lookup = self.class.lookup_for_asset('view', user_id, id)
          insert = lookup.nil?

          if insert
            sql = "insert into #{self.class.lookup_table_name} (user_id,asset_id,can_view,can_edit,can_download,can_manage,can_delete) values (#{user_id},#{id},#{can_view},#{can_edit},#{can_download},#{can_manage},#{can_delete});"
          else
            sql = "update #{self.class.lookup_table_name} set can_view=#{can_view}, can_edit=#{can_edit}, can_download=#{can_download},can_manage=#{can_manage},can_delete=#{can_delete} where user_id=#{user_id} and asset_id=#{id}"
          end

          ActiveRecord::Base.connection.execute(sql)
        end
      end

      def update_lookup_table_for_all_users
        self.class.transaction do
          # Blank-out permissions first

          # 1 entry for each user + anonymous
          if lookup_count != (User.count + 1)
            sql = %(DELETE FROM #{self.class.lookup_table_name} WHERE asset_id=#{id})
            ActiveRecord::Base.connection.execute(sql)

            f = ActiveRecord::Base.connection.quote(false)

            # Insert in batches of 10
            ([0] + User.pluck(:id)).each_slice(Seek::Util.bulk_insert_batch_size) do |batch|
              sql = %(INSERT INTO #{self.class.lookup_table_name}
                        (user_id, asset_id, can_view ,can_edit, can_download, can_manage, can_delete)
                        VALUES #{batch.map { |user_id| "(#{user_id}, #{id}, #{f}, #{f}, #{f}, #{f}, #{f})" }.join(', ')};)

              ActiveRecord::Base.connection.execute(sql)
            end
          else
            update_lookup([false, false, false, false, false], nil)
          end

          # Specific permissions (Permission)

          # Sort permissions according to precedence, then access type, so the most direct (People), permissive (Manage)
          # permissions are applied last.
          sorted_permissions = policy.permissions
                                     .sort_by { |p| Permission.precedence.index(p.contributor_type) * 100 - p.access_type }
                                     .reverse

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
            update_lookup(permission, permission.affected_people.map(&:user))
          end

          # Creator permissions
          if respond_to?(:creators) && creators.any?
            update_lookup([true, true, true, false, false], creators.includes(:user).map(&:user).compact, false)
          end

          # Contributor permissions
          if (contributor_user = (contributor.is_a?(Person) ? contributor.user : contributor))
            update_lookup([true, true, true, true, true], contributor_user)
          end

          # Role permissions (Role)
          if asset_housekeeper_can_manage?
            asset_housekeepers = projects.map(&:asset_housekeepers).flatten.map(&:user).compact
            if asset_housekeepers.any?
              update_lookup([true, true, true, true, true], asset_housekeepers)
            end
          end

          # Global permissions (Policy)
          update_lookup(policy, nil, false)

          # block from anonymous users if polidy is shared with ALL_USERS only
          update_lookup([false, false, false, false, false], :anonymous) if policy.sharing_scope == Policy::ALL_USERS
        end
      end

      def contributor_credited?
        !respond_to?(:creators) || creators.empty?
      end

      def private?
        policy.private?
      end

      def public?
        policy.public?
      end

      def default_policy
        Policy.default
      end

      def policy_or_default_if_new
        self.policy = default_policy if new_record? && !policy
      end

      def default_contributor
        User.current_user
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
        contributor = self.contributor.is_a?(Person) ? self.contributor : self.contributor.try(:person)
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
        # FIXME: how to handle projects as contributors - return all people or just specific people (pals or other role)?
        people = []
        unless contributor.nil?
          people << contributor.person if contributor.is_a?(User)
          people << contributor if contributor.is_a?(Person)
        end

        policy.permissions.each do |perm|
          unless perm.contributor.nil? || perm.access_type != Policy::MANAGING
            people << perm.contributor if perm.contributor.is_a?(Person)
            people << perm.contributor.person if perm.contributor.is_a?(User)
          end
        end
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

      def lookup_count
        sql = "select count(*) from #{self.class.lookup_table_name} where asset_id = #{id}"
        ActiveRecord::Base.connection.select_one(sql).values[0].to_i
      end

      private

      # Note, nil user means ALL users, not anonymous user. Anon user is represented with ;anonymous
      def update_lookup(permission, user = nil, overwrite = true)
        if permission.is_a?(Array)
          can_view, can_edit, can_download, can_manage, can_delete = *permission
        else
          can_view = permission.allows_action?('view')
          can_edit = permission.allows_action?('edit')
          can_download = permission.allows_action?('download')
          can_manage = permission.allows_action?('manage')
          can_delete = permission.allows_action?('delete')
        end

        sql = %(UPDATE #{self.class.lookup_table_name} SET )
        fields_to_set = %i[can_view can_edit can_download can_manage can_delete].select do |privilege|
          # Only set "true" values if not overwriting
          overwrite || binding.local_variable_get(privilege)
        end

        return if fields_to_set.empty?

        sql += fields_to_set.map do |privilege|
          "#{privilege}=#{ActiveRecord::Base.connection.quote(binding.local_variable_get(privilege))}"
        end.join(",\n")

        sql += " WHERE asset_id=#{id}"

        if user.respond_to?(:each)
          user = user.compact
          return unless user.any?
          sql += " AND user_id IN (#{user.map(&:id).join(', ')})"
        elsif user == :anonymous
          sql += ' AND user_id=0'
        elsif user.is_a?(User)
          sql += " AND user_id=#{user.id}"
        elsif user.is_a?(Person)
          sql += " AND user_id=#{user.user_id}"
        end

        sql += ';'

        ActiveRecord::Base.connection.execute(sql)
      end
    end
  end
end
