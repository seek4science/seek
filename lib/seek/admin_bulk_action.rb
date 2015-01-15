module Seek
  module AdminBulkAction

    def self.included(base)
      base.before_filter :is_admin, :only => [:bulk_destroy]
    end

    def bulk_destroy
      unless params["ids"].blank?
        begin
          model_class=self.controller_name.classify.constantize
          objects = model_class.find(params["ids"])
          objects.each(&:destroy)
          redirect_back
        rescue ActiveRecord::RecordNotFound
          respond_to do |format|
            format.html do
              render :template => "errors/error_404", :layout=>"errors",:status => :not_found
            end
          end
        end
      end
    end

    private

    def is_admin
      is_user_admin_auth
    end

  end
end
