module Seek
  module Roles
    module Scope
      extend ActiveSupport::Concern

      included do
        has_many :roles, as: :scope, dependent: :destroy, inverse_of: :scope
      end
    end
  end
end
