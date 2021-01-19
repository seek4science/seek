# Programme
#


Factory.define(:programme) do |f|
  f.sequence(:title) { |n| "A Programme: #{n}" }
  f.projects { [Factory(:project)] }
  f.after_create do |p|
    p.is_activated = true
    p.save
  end
end

Factory.define(:min_programme, class: Programme) do |f|
  f.title "A Minimal Programme"
end

Factory.define(:max_programme, class: Programme) do |f|
  f.title "A Maximal Programme"
  f.description "A very exciting programme"
  f.discussion_links { [Factory.build(:discussion_link, label:'Slack')] }
  f.web_page "http://www.synbiochem.co.uk"
  f.funding_details "Someone is funding this for me"
  f.projects { [Factory.build(:max_project)] }
end
