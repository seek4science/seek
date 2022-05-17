Factory.define(:observed_variable) do |f|
    f.variable_id 'the variable'
end

Factory.define(:observed_variable_set) do |f|
    f.title 'the observed variable set'
    f.association :contributor, factory: :person
    f.after_build do |set|
        set.observed_variables = [Factory.build(:observed_variable)]
    end
end