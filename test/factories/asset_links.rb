Factory.define(:asset_link, class: AssetLink) do |f|
  f.url "http://www.slack.com/"
  f.association :asset, factory: :model
end

Factory.define(:discussion_link, parent: :asset_link) do |f|
  f.link_type AssetLink::DISCUSSION
end

Factory.define(:misc_link, parent: :asset_link) do |f|
  f.link_type AssetLink::MISC_LINKS
end