FactoryBot.define do
  # Programme
  #
  
  
  factory(:programme) do
    sequence(:title) { |n| "A Programme: #{n}" }
    projects { [FactoryBot.create(:project)] }
    after(:create) do |p|
      p.is_activated = true
      p.save
    end
  end
  
  factory(:min_programme, class: Programme) do
    title { "A Minimal Programme" }
  end
  
  factory(:max_programme, class: Programme) do
    title { "A Maximal Programme" }
    description { "A very exciting programme" }
    discussion_links { [FactoryBot.build(:discussion_link, label:'Slack')] }
    web_page { "http://www.synbiochem.co.uk" }
    funding_details { "Someone is funding this for me" }
    projects { [FactoryBot.create(:max_project)] }
    programme_administrators { [FactoryBot.create(:person)] }
    after(:create) do |p|
      p.annotate_with(['DFG'], 'funding_code', p.programme_administrators.first)
      p.save!
    end
  end
end
