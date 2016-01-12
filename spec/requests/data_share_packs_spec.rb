require 'rails_helper'

RSpec.describe "DataSharePacks", :type => :request do
  describe "GET /data_share_packs" do
    it "works! (now write some real specs)" do
      get data_share_packs_path
      expect(response).to have_http_status(200)
    end
  end
end
