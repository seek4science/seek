module Ga4gh
  module Trs
    module V2
      class TrsBaseController < ::ApplicationController
        respond_to :json, :plain

        after_action :set_content_type

        def set_content_type
          self.content_type = "application/json"
        end
      end
    end
  end
end
