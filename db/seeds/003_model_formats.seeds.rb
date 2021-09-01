
count = ModelFormat.count
titles = YAML.load_file(File.join(Rails.root, 'config/default_data/model_formats.yml')).values.collect { |x| x['title'] }


# changes, due to some inconsistencies in the fairdomhub entries
changes = {
    "Field Modelling Markup Language (FieldML)" => "FieldML",
    "KEGG Markup Language (KGML)" => "KGML",
    "VCell" => "Virtual Cell Markup Language (VCML)",
    "MathML/Smile" => "MathML"
}

changes.keys.each do |change|
  if (format = ModelFormat.find_by(title:change))
    format.update_column(:title,changes[change])
  end
end


titles.each do |title|
  unless ModelFormat.find_by(title: title)
    ModelFormat.find_or_create_by(title: title)
  end
end


