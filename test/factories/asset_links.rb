FactoryBot.define do
  factory(:asset_link, class: AssetLink) do
    url { 'http://www.slack.com/' }
    association :asset, factory: :model
  end

  factory(:discussion_link, parent: :asset_link) do
    link_type { AssetLink::DISCUSSION }
  end

  factory(:misc_link, parent: :asset_link) do
    link_type { AssetLink::MISC_LINKS }
  end
end
