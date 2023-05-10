FactoryBot.define do
  # Institution
  factory(:institution) do
    sequence(:title) { |n| "An Institution: #{n}" }
    country { 'GB' }
  end
  
  factory(:min_institution, class: Institution) do
    title { "A Minimal Institution" }
    country { "DE" }
  end
  
  factory(:max_institution, class: Institution) do
    title { "A Maximal Institution" }
    country { "GB" }
    city { "Manchester" }
    address { "Manchester Centre for Integrative Systems Biology, MIB/CEAS, The University of Manchester Faraday Building, Sackville Street, Manchester M60 1QD United Kingdom" }
    web_page { "http://www.mib.ac.uk/" }
    discussion_links { [FactoryBot.build(:discussion_link, label:'Slack')] }
  end
end
