require 'project_compat'
module Acts
  module Authorized
    module PolicyBasedAuthorization
      def self.included klass
        klass.extend ClassMethods
        klass.extend AuthLookupMethods
        klass.class_eval do
          belongs_to :contributor, :polymorphic => true unless method_defined? :contributor
          after_initialize :contributor_or_default_if_new

          #checks a policy exists, and if missing resorts to using a private policy
          after_initialize :policy_or_default_if_new

          include ProjectCompat unless method_defined? :projects

          belongs_to :policy, :required_access_to_owner => :manage, :autosave => true
        end
      end

      module ClassMethods

      end

      module AuthLookupMethods
        def all_authorized_for action, user=User.current_user
          user_id = user.nil? ? 0 : user.id
          c = lookup_count_for_action_and_user user_id
          if (c==count)
            Rails.logger.warn("Lookup table is complete for user_id = #{user_id}")
            ids = lookup_ids_for_person_and_action action, user_id
            find_all_by_id(ids)
          else
            Rails.logger.warn("Lookup table is incomplete for user_id = #{user_id} - doing things the slow way")
            #trigger background task to update table
            all.select { |df| df.send("can_#{action}?") }
          end
        end

        def lookup_table_name
          "#{self.name.underscore}_auth_lookup"
        end

        def clear_lookup_table
          ActiveRecord::Base.connection.execute("delete from #{lookup_table_name}")
        end

        def lookup_ids_for_person_and_action action,user_id
          ActiveRecord::Base.connection.select_all("select asset_id from #{lookup_table_name} where user_id = #{user_id} and can_#{action}=true").collect{|k| k.values}.flatten
        end

        def lookup_count_for_action_and_user user_id
          ActiveRecord::Base.connection.select_one("select count(*) from #{lookup_table_name} where user_id = #{user_id}").values[0].to_i
        end

        def lookup_for_asset action,user_id,asset_id
          attribute = "can_#{action}"
          res = ActiveRecord::Base.connection.select_one("select #{attribute} from #{lookup_table_name} where user_id=#{user_id} and asset_id=#{asset_id}")
          if res.nil?
            nil
          else
            res[attribute] == "1" || res[attribute]==true
          end
        end
      end

      AUTHORIZATION_ACTIONS.each do |action|
          eval <<-END_EVAL
            def can_#{action}? user = User.current_user
                return true if new_record?
                user_id = user.nil? ? 0 : user.id
                lookup = self.class.lookup_for_asset("#{action}", user_id,self.id)
                if lookup.nil?
                  perform_auth(user,"#{action}")
                else
                  lookup
                end
            end
          END_EVAL
      end

      def update_lookup_table user=nil
        user_id = user.nil? ? 0 : user.id

        sql = "delete from #{self.class.lookup_table_name} where user_id=#{user_id} and asset_id=#{id}"
        ActiveRecord::Base.connection.execute(sql)
        sql = "insert into #{self.class.lookup_table_name} (user_id,asset_id,can_view,can_edit,can_download,can_manage,can_delete) values (#{user_id},#{id},#{can_view?(user)},#{can_edit?(user)},#{can_download?(user)},#{can_manage?(user)},#{can_delete?(user)});"
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
      #contritutor or person who can manage the item and the item was published
      def can_publish?
        ((Ability.new(User.current_user).can? :publish, self) && self.can_manage?) || self.contributor == User.current_user || try_block{self.contributor.user} == User.current_user || (self.can_manage? && self.policy.sharing_scope == Policy::EVERYONE) || Seek::Config.is_virtualliver
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

      def cache_keys user, action

        #start off with the keys for the person
        unless user.try(:person).nil?
          keys = user.person.generate_person_key
        else
          keys = []
        end

        #action
        keys << "can_#{action}?"

        #item (to invalidate when contributor is changed)
        keys << self.cache_key

        #item creators (to invalidate when creators are changed)
        if self.respond_to? :assets_creators
          keys |= self.assets_creators.sort_by(&:id).collect(&:cache_key)
        end

        #policy
        keys << policy.cache_key

        #permissions
        keys |= policy.permissions.sort_by(&:id).collect(&:cache_key)

        keys
      end
    end
  end
end
