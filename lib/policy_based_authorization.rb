require 'project_compat'
module Acts
  module Authorized
    module PolicyBasedAuthorization
      def self.included klass
        attr_accessor :permission_for
        klass.extend ClassMethods
        klass.extend AuthLookupClassMethods
        klass.class_eval do
          belongs_to :contributor, :polymorphic => true unless method_defined? :contributor
          after_initialize :contributor_or_default_if_new

          #checks a policy exists, and if missing resorts to using a private policy
          after_initialize :policy_or_default_if_new

          include ProjectCompat unless method_defined? :projects

          belongs_to :policy, :required_access_to_owner => :manage, :autosave => true

          before_validation :temporary_policy_while_waiting_for_publishing_approval, :publishing_auth, :unless => "Seek::Config.is_virtualliver"
          after_save :queue_update_auth_table
          after_destroy :remove_from_lookup_table
          before_save :update_timestamp_if_policy_was_saved, :if => "Seek::Config.is_virtualliver"

          def update_timestamp_if_policy_was_saved
            #autosaved belongs_to associations get saved before the parent, so to check if it has changed, see if it has a newer updated_at
            update_timestamp if updated_at && policy.updated_at > updated_at
          end


        end
      end

      module ClassMethods

      end

      module AuthLookupClassMethods

        #returns all the authorised items for a given action and optionally a user and set of projects. If user is nil, the items authorised for an
        #anonymous user are returned. If one or more projects are provided, then only the assets linked to those projects are included.
        def all_authorized_for action, user=User.current_user, projects=nil
          projects=Array(projects) unless projects.nil?
          user_id = user.nil? ? 0 : user.id
          assets = []
          programatic_project_filter = !projects.nil? && (!Seek::Config.auth_lookup_enabled || (self==Assay || self==Study))
          if Seek::Config.auth_lookup_enabled
            if (lookup_table_consistent?(user_id))
              Rails.logger.info("Lookup table #{lookup_table_name} is complete for user_id = #{user_id}")
              assets = lookup_for_action_and_user action, user_id, projects
            else
              Rails.logger.info("Lookup table #{lookup_table_name} is incomplete for user_id = #{user_id} - doing things the slow way")
              assets = all.select { |df| df.send("can_#{action}?") }
              programatic_project_filter = !projects.nil?
            end
          else
            assets = all.select { |df| df.send("can_#{action}?") }
          end
          if programatic_project_filter
            assets.select { |a| !(a.projects & projects).empty? }
          else
            assets
          end
        end

        #returns the authorised items from the array of the same class items for a given action and optionally a user. If user is nil, the items authorised for an
        #anonymous user are returned.
        def authorized_partial_asset_collection partial_asset_collection, action, user=User.current_user
          #FIXME: just a quick fix - needs more careful analysis of the ratio between the current collection and the total
          size_for_intersection_with_all = 50
          user_id = user.nil? ? 0 : user.id
          authorized_assets = []
          authorized_partial_asset_collection = []
          lookup_table_name = self.name.underscore.pluralize + '_auth_lookup'
          if (partial_asset_collection.size>=size_for_intersection_with_all && self.lookup_table_consistent?(user_id))
            Rails.logger.info("Lookup table #{lookup_table_name} used for authorizing related items is complete for user_id = #{user_id}")
            authorized_assets = self.lookup_for_action_and_user action, user_id, nil
            authorized_partial_asset_collection = authorized_assets & partial_asset_collection
          else
            authorized_partial_asset_collection = partial_asset_collection.select{|a| a.send("can_#{action}?")}
          end
          authorized_partial_asset_collection
        end

        #determines whether the lookup table records are consistent with the number of asset items in the database and the last id of the item added
        def lookup_table_consistent? user_id
          unless user_id.is_a?(Numeric)
            user_id = user_id.nil? ? 0 : user_id.id
          end
          #cannot rely purely on the count, since an item could have been deleted and a new one added
          c = lookup_count_for_user user_id
          last_stored_asset_id = last_asset_id_for_user user_id
          last_asset_id = self.last(:order=>:id).try(:id)

          #trigger off a full update for that user if the count is zero and items should exist for that type
          if (c==0 && !last_asset_id.nil?)
            AuthLookupUpdateJob.add_items_to_queue User.find_by_id(user_id)
          end
          c==count && (count==0 || (last_stored_asset_id == last_asset_id))
        end

        #the name of the lookup table, holding authorisation lookup information, for this given authorised type
        def lookup_table_name
          "#{self.name.underscore}_auth_lookup"
        end

        #removes all entries from the authorization lookup type for this authorized type
        def clear_lookup_table
          ActiveRecord::Base.connection.execute("delete from #{lookup_table_name}")
        end

        #the record count for entries within the authorization lookup table for a given user_id or user. Used to determine if the table is complete
        def lookup_count_for_user user_id
          unless user_id.is_a?(Numeric)
            user_id = user_id.nil? ? 0 : user_id.id
          end
          ActiveRecord::Base.connection.select_one("select count(*) from #{lookup_table_name} where user_id = #{user_id}").values[0].to_i
        end

        def lookup_for_action_and_user action,user_id,projects
          #Study's and Assays have to be treated differently, as they are linked to a project through the investigation'
          if (projects.nil? || (self == Study || self == Assay))
            sql = "select asset_id from #{lookup_table_name} where user_id = #{user_id} and can_#{action}=#{ActiveRecord::Base.connection.quoted_true}"
            ids = ActiveRecord::Base.connection.select_all(sql).collect{|k| k["asset_id"]}
          else
            project_map_table = ["#{self.name.underscore.pluralize}", 'projects'].sort.join('_')
            project_map_asset_id = "#{self.name.underscore}_id"
            project_clause = projects.collect{|p| "#{project_map_table}.project_id = #{p.id}"}.join(" or ")
            sql = "select asset_id,#{project_map_asset_id} from #{lookup_table_name}"
            sql << " inner join #{project_map_table}"
            sql << " on #{lookup_table_name}.asset_id = #{project_map_table}.#{project_map_asset_id}"
            sql << " where #{lookup_table_name}.user_id = #{user_id} and (#{project_clause})"
            sql << " and can_#{action}=#{ActiveRecord::Base.connection.quoted_true}"
            ids = ActiveRecord::Base.connection.select_all(sql).collect{|k| k["asset_id"]}
          end
          find_all_by_id(ids)
        end

        #the highest asset id recorded in authorization lookup table for a given user_id or user. Used to determine if the table is complete
        def last_asset_id_for_user user_id
          unless user_id.is_a?(Numeric)
            user_id = user_id.nil? ? 0 : user_id.id
          end
          v = ActiveRecord::Base.connection.select_one("select max(asset_id) from #{lookup_table_name} where user_id = #{user_id}").values[0]
          v.nil? ? -1 : v.to_i
        end

        #looks up the entry in the authorization lookup table for a single authorised type, for a given action, user_id and asset_id. A user id of zero
        #indicates an anonymous user. Returns nil if there is no record available
        def lookup_for_asset action,user_id,asset_id
          attribute = "can_#{action}"
          @@expected_true_value ||= ActiveRecord::Base.connection.quoted_true.gsub("'","")
          res = ActiveRecord::Base.connection.select_one("select #{attribute} from #{lookup_table_name} where user_id=#{user_id} and asset_id=#{asset_id}")
          if res.nil?
            nil
          else
            res[attribute]==@@expected_true_value
          end
        end
      end

      def auth_key user, action
        [user.try(:person).try(:cache_key), "can_#{action}?", cache_key]
      end

      #removes all entries related to this item from the authorization lookup table
      def remove_from_lookup_table
        id=self.id
        ActiveRecord::Base.connection.execute("delete from #{self.class.lookup_table_name} where asset_id=#{id}")
      end

      AUTHORIZATION_ACTIONS.each do |action|
        eval <<-END_EVAL
            def can_#{action}? user = User.current_user
                return true if new_record?
                user_id = user.nil? ? 0 : user.id
                if Seek::Config.auth_lookup_enabled
                  lookup = self.class.lookup_for_asset("#{action}", user_id,self.id)
                else
                  lookup=nil
                end
                if lookup.nil?
                  perform_auth(user,"#{action}")
                else
                  lookup
                end
            end
        END_EVAL

      end

      #triggers a background task to update or create the authorization lookup table records for this item
      def queue_update_auth_table
        #FIXME: somewhat aggressively does this after every save can be refined in the future
        unless (self.changed - ["updated_at", "last_used_at"]).empty?
          AuthLookupUpdateJob.add_items_to_queue self
        end
      end

      #updates or creates the authorization lookup entries for this item and the provided user (nil indicating anonymous user)
      def update_lookup_table user=nil
        user_id = user.nil? ? 0 : user.id

        can_view = ActiveRecord::Base.connection.quote perform_auth(user,"view")
        can_edit = ActiveRecord::Base.connection.quote perform_auth(user,"edit")
        can_download = ActiveRecord::Base.connection.quote perform_auth(user,"download")
        can_manage = ActiveRecord::Base.connection.quote perform_auth(user,"manage")
        can_delete = ActiveRecord::Base.connection.quote perform_auth(user,"delete")

        #check to see if an insert of update is needed, action used is arbitary
        lookup = self.class.lookup_for_asset("view",user_id,self.id)
        insert = lookup.nil?

        if insert
          sql = "insert into #{self.class.lookup_table_name} (user_id,asset_id,can_view,can_edit,can_download,can_manage,can_delete) values (#{user_id},#{id},#{can_view},#{can_edit},#{can_download},#{can_manage},#{can_delete});"
        else
          sql = "update #{self.class.lookup_table_name} set can_view=#{can_view}, can_edit=#{can_edit}, can_download=#{can_download},can_manage=#{can_manage},can_delete=#{can_delete} where user_id=#{user_id} and asset_id=#{id}"
        end

        ActiveRecord::Base.connection.execute(sql)

      end

      def contributor_credited?
        true
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

      def policy_or_default
        if self.policy.nil?
          self.policy = default_policy
        end
      end

      def policy_or_default_if_new
        if self.new_record?
          policy_or_default
        end
      end

      def default_contributor
        User.current_user
      end

      #when having a sharing_scope policy of Policy::ALL_SYSMO_USERS it is concidered to have advanced permissions if any of the permissions do not relate to the projects associated with the resource (ISA or Asset))
      #this is a temporary work-around for the loss of the custom_permissions flag when defining a pre-canned permission of shared with sysmo, but editable/downloadable within mhy project
      #other policy sharing scopes are simpler, and are concidered to have advanced permissions if there are more than zero permissions defined
      def has_advanced_permissions?
        if policy.sharing_scope==Policy::ALL_SYSMO_USERS
          !(policy.permissions.collect{|p| p.contributor} - projects).empty?
        else
          policy.permissions.count > 0
        end
      end

      def contributor_or_default_if_new
        if self.new_record? && contributor.nil?
          self.contributor = default_contributor
        end
      end
      #(gatekeeper also manager) or (manager and projects have no gatekeeper) or (manager and the item was published)
      def can_publish? user=User.current_user
        if self.new_record?
          (Ability.new(user).can? :publish, self) || (self.can_manage? && self.gatekeepers.empty?) || Seek::Config.is_virtualliver
        else
          (Ability.new(user).can? :publish, self) || (self.can_manage? && self.gatekeepers.empty?) || (self.can_manage? && (self.policy.sharing_scope_was == Policy::EVERYONE)) || Seek::Config.is_virtualliver
        end
      end

      #use request_permission_summary to retrieve who can manage the item
      def people_can_manage
        contributor = self.contributor.kind_of?(Person) ? self.contributor : self.contributor.try(:person)
        return [[contributor.id, "#{contributor.first_name} #{contributor.last_name}", Policy::MANAGING]] if policy.blank?
        creators = is_downloadable? ? self.creators : []
        asset_managers = projects.collect(&:asset_managers).flatten
        grouped_people_by_access_type = policy.summarize_permissions creators,asset_managers, contributor
        grouped_people_by_access_type[Policy::MANAGING]
      end

      def perform_auth user,action
        (Authorization.is_authorized? action, nil, self, user) || (Ability.new(user).can? action.to_sym, self) || (Ability.new(user).can? "#{action}_asset".to_sym, self)
      end

      #returns a list of the people that can manage this file
      #which will be the contributor, and those that have manage permissions
      def managers
        #FIXME: how to handle projects as contributors - return all people or just specific people (pals or other role)?
        people=[]
        unless self.contributor.nil?
          people << self.contributor.person if self.contributor.kind_of?(User)
          people << self.contributor if self.contributor.kind_of?(Person)
        end

        self.policy.permissions.each do |perm|
          unless perm.contributor.nil? || perm.access_type!=Policy::MANAGING
            people << (perm.contributor) if perm.contributor.kind_of?(Person)
            people << (perm.contributor.person) if perm.contributor.kind_of?(User)
          end
        end
        people.uniq
      end

      def contributing_user
        unless self.kind_of?(Assay)
          if contributor.kind_of?Person
            contributor.try(:user)
          elsif contributor.kind_of?User
            contributor
          else
            nil
          end
        else
          owner.try(:user)
        end
      end

      def gatekeepers
         self.projects.collect(&:gatekeepers).flatten
      end

      def publishing_auth
        return true if $authorization_checks_disabled
        #only check if doing publishing
        if self.policy.sharing_scope == Policy::EVERYONE && !self.kind_of?(Publication)
            unless self.can_publish?
              errors.add_to_base("You are not permitted to publish this #{self.class.name.underscore.humanize}")
              return false
            end
        end
      end

      #while item is waiting for publishing approval,set the policy of the item to:
      #new item: sysmo_and_project_policy
      #updated item: keep the policy as before
      def temporary_policy_while_waiting_for_publishing_approval
        return true if $authorization_checks_disabled
        if self.new_record? && self.policy.sharing_scope == Policy::EVERYONE && !self.kind_of?(Publication) && !self.can_publish?
          self.policy = Policy.sysmo_and_projects_policy self.projects
        elsif !self.new_record? && self.policy.sharing_scope == Policy::EVERYONE && !self.kind_of?(Publication) && !self.can_publish?
          self.policy = Policy.find_by_id(self.policy.id)
        end
      end

      #members of project can see some information of hidden items of their project
      def can_see_hidden_item?(person)
        person.member_of?(self.projects)
      end
    end
  end
end
