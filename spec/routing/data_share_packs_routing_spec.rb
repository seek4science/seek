require "rails_helper"

RSpec.describe DataSharePacksController, :type => :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/data_share_packs").to route_to("data_share_packs#index")
    end

    it "routes to #new" do
      expect(:get => "/data_share_packs/new").to route_to("data_share_packs#new")
    end

    it "routes to #show" do
      expect(:get => "/data_share_packs/1").to route_to("data_share_packs#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/data_share_packs/1/edit").to route_to("data_share_packs#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/data_share_packs").to route_to("data_share_packs#create")
    end

    it "routes to #update" do
      expect(:put => "/data_share_packs/1").to route_to("data_share_packs#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/data_share_packs/1").to route_to("data_share_packs#destroy", :id => "1")
    end

  end
end
