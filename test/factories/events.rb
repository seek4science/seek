FactoryBot.define do
  # Event
  factory(:event) do
    with_project_contributor
    title { 'An Event' }
    start_date { Time.now }
    after(:build) {|e| e.end_date = e.start_date + 1.day if e.end_date.blank?}
  end
  
  factory(:min_event, class: Event) do
    with_project_contributor
    title { 'A Minimal Event' }
    start_date { "2017-01-01T00:01:00.000Z" }
    projects { [FactoryBot.create(:min_project)] }
  end
  
  factory(:max_event, class: Event) do
    with_project_contributor
    title { 'A Maximal Event' }
    description { 'All you ever wanted to know about headaches' }
    url { 'http://www.headache-center.org' }
    city { 'Heidelberg' }
    country { 'DE' }
    address { 'Sofienstr 2' }
    start_date { "2017-01-01T00:20:00.000Z" }
    end_date { "2017-01-01T00:22:00.000Z" }
    data_files {[FactoryBot.create(:data_file, policy: FactoryBot.create(:public_policy))]}
    publications {[FactoryBot.create(:publication)]}
    presentations {[FactoryBot.create(:presentation, policy: FactoryBot.create(:public_policy))]}
  end
end
