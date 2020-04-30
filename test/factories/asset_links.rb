Factory.define(:asset_link, class: AssetLink) do |f|
  f.url "http://www.slack.com/"
  f.link_type AssetLink::DISCUSSION
  f.association :asset, factory: :model
end