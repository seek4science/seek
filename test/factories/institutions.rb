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
    title { "University of Manchester" }
    department { "Manchester Institute of Biotechnology" }
    country { "GB" }
    city { "Manchester" }
    ror_id { "027m9bs27" }
    address { "Manchester Centre for Integrative Systems Biology, MIB/CEAS, The University of Manchester Faraday Building, Sackville Street, Manchester M60 1QD United Kingdom" }
    web_page { "http://www.manchester.ac.uk/" }
    discussion_links { [FactoryBot.build(:discussion_link, label:'Slack')] }
  end
end
