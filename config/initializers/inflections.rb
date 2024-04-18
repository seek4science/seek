  # Be sure to restart your server when you modify this file.
SEEK::Application.configure do

  ActiveSupport::Inflector.inflections do |inflect|
    inflect.irregular "specimen","specimens"
    inflect.irregular "data","data"
    inflect.acronym "HTML"
    inflect.acronym "JSON"
    inflect.acronym "CSV"
    inflect.acronym "HTTP"
    inflect.acronym "FTP"
    inflect.acronym "JERM"
    inflect.acronym "ROCrate"
    inflect.acronym "CWL"
    inflect.acronym "KNIME"
  end
end
