module SharingFormTestHelper
    def valid_sharing
      {
          :use_whitelist =>"0",
          :user_blacklist=>"0",
          :sharing_scope =>Policy::ALL_USERS,
          "access_type_#{Policy::ALL_USERS}".to_sym => Policy::VISIBLE,
          :permissions   =>{:contributor_types=>ActiveSupport::JSON.encode(["\"Person\""]), :values=>ActiveSupport::JSON.encode({})}
      }
  end
end