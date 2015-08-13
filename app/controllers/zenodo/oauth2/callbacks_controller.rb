module Zenodo
  module Oauth2
    class CallbacksController < ApplicationController

      def callback
        redirect_to "#{params[:state]}?code=#{params[:code]}"
      end

    end
  end
end
