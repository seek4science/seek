require 'rails_helper'

RSpec.describe "data_share_packs/edit", :type => :view do
  before(:each) do
    @data_share_pack = assign(:data_share_pack, DataSharePack.create!(
      :title => "MyString",
      :description => "MyString"
    ))
  end

  it "renders the edit data_share_pack form" do
    render

    assert_select "form[action=?][method=?]", data_share_pack_path(@data_share_pack), "post" do

      assert_select "input#data_share_pack_title[name=?]", "data_share_pack[title]"

      assert_select "input#data_share_pack_description[name=?]", "data_share_pack[description]"
    end
  end
end
