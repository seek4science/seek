# Institution
Factory.define(:institution) do |f|
  f.sequence(:title) { |n| "An Institution: #{n}" }
  f.country 'GB'
end

Factory.define(:min_institution, class: Institution) do |f|
  f.title "A Minimal Institution"
  f.country "DE"
end

Factory.define(:max_institution, class: Institution) do |f|
  f.title "A Maximal Institution"
  f.country "GB"
  f.city "Manchester"
  f.address "Manchester Centre for Integrative Systems Biology, MIB/CEAS, The University of Manchester Faraday Building, Sackville Street, Manchester M60 1QD United Kingdom"
  f.web_page "http://www.mib.ac.uk/"
end
