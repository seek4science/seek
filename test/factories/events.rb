FactoryBot.define do
  # Event
  factory(:event) do
    with_project_contributor
    title 'An Event'
    start_date Time.now
    after_build {|e| e.end_date = e.start_date + 1.day if e.end_date.blank?}
  end
  
  factory(:min_event, class: Event) do
    with_project_contributor
    title 'A Minimal Event'
    start_date "2017-01-01T00:01:00.000Z"
    projects { [Factory(:min_project)] }
  end
  
  factory(:max_event, class: Event) do
    with_project_contributor
    title 'A Maximal Event'
    description 'All you ever wanted to know about headaches'
    url 'http://www.headache-center.org'
    city 'Heidelberg'
    country 'DE'
    address 'Sofienstr 2'
    start_date "2017-01-01T00:20:00.000Z"
    end_date "2017-01-01T00:22:00.000Z"
    data_files {[Factory(:data_file, policy: Factory(:public_policy))]}
    publications {[Factory(:publication)]}
    presentations {[Factory(:presentation, policy: Factory(:public_policy))]}
  end
end
