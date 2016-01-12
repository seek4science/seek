require 'rails_helper'

RSpec.describe "data_share_packs/index", :type => :view do
  before(:each) do
    assign(:data_share_packs, [
      DataSharePack.create!(
        :title => "Title",
        :description => "Description"
      ),
      DataSharePack.create!(
        :title => "Title",
        :description => "Description"
      )
    ])
  end

  it "renders a list of data_share_packs" do
    render
    assert_select "tr>td", :text => "Title".to_s, :count => 2
    assert_select "tr>td", :text => "Description".to_s, :count => 2
  end
end
