require 'rails_helper'

RSpec.describe "data_share_packs/show", :type => :view do
  before(:each) do
    @data_share_pack = assign(:data_share_pack, DataSharePack.create!(
      :title => "Title",
      :description => "Description"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Title/)
    expect(rendered).to match(/Description/)
  end
end
