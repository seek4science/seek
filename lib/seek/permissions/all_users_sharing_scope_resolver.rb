module Seek
  module Permissions
    # Handles detecting items with a policy sharing_scope ALL_USERS, and changing the permissions so that
    # the sharing scope is removed, but is shared with with same access type with associated projects. This is to remove
    # the legacy policy, and is part of an upgrade described by: https://jira-bsse.ethz.ch/browse/OPSK-1494
    class AllUsersSharingScopeResolver

      def resolve(authorized_item)
        authorized_item
      end
    end
  end
end
