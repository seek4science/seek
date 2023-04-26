FactoryBot.define do
  factory(:observed_variable) do
      variable_id { 'the variable' }
  end
  
  factory(:observed_variable_set) do
      title { 'the observed variable set' }
      association :contributor, factory: :person
      after_build do |set|
          set.observed_variables = [Factory.build(:observed_variable)]
      end
  end
end
