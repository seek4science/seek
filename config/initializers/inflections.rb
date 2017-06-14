  # Be sure to restart your server when you modify this file.
SEEK::Application.configure do

  ActiveSupport::Inflector.inflections do |inflect|
    inflect.irregular "specimen","specimens"
  end

  #the Inflector module's definition of 'humanize' does not act
  #according to the Inflector::Inflections#human documentation.
  #This changes Inflector#humanize to follow the documentation.
  #
  #The human method's documentation states that regex based rules
  #get the normal humanize behavior applied after they run, but strings
  #should not. The default implementation runs the normal humanize behavior no
  #matter what.
  # ActiveSupport::Inflector.class_eval do
  #   def humanize_with_skipping_normal_behaviour_for_string_based_rules underscored_string
  #     string_based_rules = inflections.humans.select {|(rule, replacement)| rule.is_a? String}
  #     string_based_replacement = string_based_rules.detect { |(rule, replacement)| underscored_string.to_s == rule ? replacement : nil }.try :last
  #     string_based_replacement || humanize_without_skipping_normal_behaviour_for_string_based_rules(underscored_string)
  #   end
  #   alias_method_chain :humanize, :skipping_normal_behaviour_for_string_based_rules
  # end
end


