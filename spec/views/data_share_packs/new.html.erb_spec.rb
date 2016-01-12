require 'rails_helper'

RSpec.describe "data_share_packs/new", :type => :view do
  before(:each) do
    assign(:data_share_pack, DataSharePack.new(
      :title => "MyString",
      :description => "MyString"
    ))
  end

  it "renders new data_share_pack form" do
    render

    assert_select "form[action=?][method=?]", data_share_packs_path, "post" do

      assert_select "input#data_share_pack_title[name=?]", "data_share_pack[title]"

      assert_select "input#data_share_pack_description[name=?]", "data_share_pack[description]"
    end
  end
end
