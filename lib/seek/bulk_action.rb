module Seek
  module BulkAction
    include IndexPager

    def self.included klass
      klass.before_filter :only => [:bulk_destroy] do |filter|
        filter.find_assets "destroy"
      end
    end

    def bulk_destroy
      objects = params["ids"].blank? ? [] : assets.select{|res| params["ids"].include?(res.id.to_s)}
      objects.each(&:destroy)
       redirect_back
    end

    private

    def assets
      controller = self.controller_name.downcase
      eval("@#{controller}")
    end

  end
end
