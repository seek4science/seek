FactoryBot.define do
  factory(:observed_variable) do
    variable_id { 'the variable' }
  end

  factory(:observed_variable_set) do
    title { 'the observed variable set' }
    association :contributor, factory: :person, strategy: :create
    after(:build) do |set|
      set.observed_variables = [FactoryBot.build(:observed_variable)]
    end
  end
end
