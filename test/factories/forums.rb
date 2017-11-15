# Forum
Factory.define :forum do |f|
  f.name 'a forum'
end

# Topic
Factory.define :topic do |f|
  f.title 'a topic'
  f.body 'topic body'
  f.association :user, factory: :user
  f.association :forum, factory: :forum
end

# Post
Factory.define :post do |f|
  f.body 'post body'
  f.association :user, factory: :user
  f.association :topic, factory: :topic
end
