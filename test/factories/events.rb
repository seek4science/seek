# Event
Factory.define(:event) do |f|
  f.with_project_contributor
  f.title 'An Event'
  f.start_date Time.now
  f.end_date 1.days.from_now
end

Factory.define(:min_event, class: Event) do |f|
  f.with_project_contributor
  f.title 'A Minimal Event'
  f.start_date "2017-01-01T00:01:00.000Z"
  f.projects { [Factory.build(:min_project)] }
end

Factory.define(:max_event, class: Event) do |f|
  f.with_project_contributor
  f.title 'A Maximal Event'
  f.description 'All you ever wanted to know about headaches'
  f.url 'http://www.headache-center.org'
  f.city 'Heidelberg'
  f.country 'Germany'
  f.address 'Sofienstr 2'
  f.start_date "2017-01-01T00:20:00.000Z"
  f.end_date "2017-01-01T00:22:00.000Z"
  f.projects { [Factory.build(:max_project)] }
  f.data_files {[Factory(:data_file, policy: Factory(:public_policy))]}
  f.publications {[Factory(:publication)]}
  f.presentations {[Factory(:presentation, policy: Factory(:public_policy))]}
end
