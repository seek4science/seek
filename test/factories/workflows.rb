# Workflow
Factory.define(:workflow) do |f|
  f.sequence(:title) { |n| "A Workflow_#{n}" }
  f.projects { [Factory.build(:project)] }
  f.association :contributor, factory: :person
  f.association :category, factory: :workflow_category
  f.after_create do |workflow|
    if workflow.content_blob.blank?
      workflow.content_blob = Factory.create(:enm_workflow, asset: workflow, asset_version: workflow.version)
    else
      workflow.content_blob.asset = workflow
      workflow.content_blob.asset_version = workflow.version
      workflow.content_blob.save
    end
  end
end

# Workflow Category
Factory.define :workflow_category do |f|
  f.name 'a category'
end

# Run
Factory.define(:taverna_player_run, class: TavernaPlayer::Run) do |f|
  f.sequence(:name) { |n| "Workflow Run #{n}" }
  f.projects { [Factory.build(:project)] }
  f.association :workflow, factory: :workflow
  f.association :contributor, factory: :person
end

Factory.define(:failed_run, parent: :taverna_player_run) do |f|
  f.status_message_key 'failed'
  f.state :failed
end

# Sweep
Factory.define(:sweep) do |f|
  f.sequence(:name) { |n| "Sweep #{n}" }
  f.projects { [Factory.build(:project)] }
  f.association :workflow, factory: :workflow
  f.association :contributor, factory: :person
end

Factory.define(:sweep_with_runs, parent: :sweep) do |f|
  f.after_create do |sweep|
    5.times do |_i|
      Factory.build(:taverna_player_run, sweep: sweep)
    end
  end
end
