module Seek
  module Roles
    module Scope
      extend ActiveSupport::Concern
      included do
        has_many :roles, as: :scope, dependent: :destroy, inverse_of: :scope
        has_many :people_with_roles, through: :roles, source: :person, class_name: 'Person'
      end

      def people_with_role(key)
        Person.with_role(key).where(roles: { scope_id: self.id, scope_type: self.class.name })
      end
    end
  end
end
