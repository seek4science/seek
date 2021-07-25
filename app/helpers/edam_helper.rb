module EdamHelper

  require 'csv'

#  @@data_json = []
#  @@format_json = []
#  @@all_jsons = []
  @@edam_table = nil

  def self.ensure_edam_table
    file = File.join(Rails.root, 'public', 'EDAM.csv')
    @@edam_table = CSV.parse(File.read(file), headers: true)

  end

  def self.edam_table
    ensure_edam_table
    return @@edam_table
  end
  
 # def self.ensure_data_json
#    if @@data_json.empty?
#      data_file = File.join(Rails.root, 'public', 'EDAM-data.json')
#      @@data_json = JSON.parse(File.read(data_file))
#    end
#  end

#  def self.ensure_format_json
#    if @@format_json.empty?
#      format_file = File.join(Rails.root, 'public', 'EDAM-format.json')
#      @@format_json = JSON.parse(File.read(format_file))
#    end
#  end

#  def self.ensure_jsons
#    ensure_data_json
#    ensure_format_json
#    @@all_jsons = @@data_json + @@format_json
#   end

#  def self.data_json
#    ensure_data_json
     
#    return @@data_json.to_json
#  end
  
#  def self.format_json
#    ensure_format_json
#    return @@format_json
#  end
  
#  def self.url_to_text(url)
#    ensure_jsons
#    matching_entry = @@all_jsons.find { |entry| entry['id'] == url }
#    result = matching_entry['text'] unless matching_entry.nil?
#    return result
#  end

   def self.url_to_text(url)
    ensure_edam_table
    if url.include? '#'
      url = url.partition('#').last
    end
    result = nil
    row = @@edam_table.find {|row| row['Class ID'] == url}
    result = row['Preferred Label'] unless row.nil?
    return result
  end

   def self.ancestry(ancestor_id, descendant_id)
     return false
    ensure_jsons
    ancestor = @@all_jsons.find { |entry| entry['id'] == ancestor_id }
    descendant =  @@all_jsons.find { |entry| entry['id'] == descendant_id }
    result = descendant['id'] == ancestor['id']
    while !result do
      descendant = @@all_jsons.find { |entry| entry['id'] == descendant['parent'] }
      break if descendant.nil?
      result = descendant['id'] == ancestor['id']
    end
    return result
  end
end
