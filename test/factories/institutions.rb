# Institution
Factory.define(:institution) do |f|
  f.sequence(:title) { |n| "An Institution: #{n}" }
  f.country { ISO3166::Country.all.sample.name }
end

Factory.define(:min_institution, class: Institution) do |f|
  f.title "A Minimal Institution"
  f.country "Germany"
end

Factory.define(:max_institution, class: Institution) do |f|
  f.title "A Maximal Institution"
  f.country "United Kingdom"
  f.city "Manchester"
  f.address "Manchester Centre for Integrative Systems Biology, MIB/CEAS, The University of Manchester Faraday Building, Sackville Street, Manchester M60 1QD United Kingdom"
  f.web_page "http://www.mib.ac.uk/"
end
