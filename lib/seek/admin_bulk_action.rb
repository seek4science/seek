module Seek
  module AdminBulkAction
    def self.included(base)
      base.before_action :is_admin, only: [:bulk_destroy]
    end

    def bulk_destroy
      unless params['ids'].blank?
        model_class = controller_name.classify.constantize
        objects = model_class.find(params['ids'])
        objects.each(&:destroy)
        redirect_back
      end
    end

    private

    def is_admin
      is_user_admin_auth
    end
  end
end
