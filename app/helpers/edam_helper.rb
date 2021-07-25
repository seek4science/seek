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

  def self.find_row(url)
    ensure_edam_table
    if url.include? '#'
      url = url.partition('#').last
    end
    result = nil
    row = @@edam_table.find {|row| row['Class ID'] == url}
    return row
  end
  
   def self.url_to_text(url)
    row = find_row(url)
    result = row['Preferred Label'] unless row.nil?
    return result
  end

   def self.ancestry(ancestor_id, descendant_id)
   ensure edam_table
     ancestors = [descendant_id]
     to_consider = [descendant_id]
    while (!ancestors.include? ancestor_id) && !to_consider.empty? do
      considering = to_consider.pop
      considering_row = find_row(considering)
      if considering_row.nil?
        break
      end
      new_parents = considering_row['Parents']
      unless new_parents.empty?
        new_parents.split.each do |p|
          unless (ancestors.include?(p) || to_consider.include?(p))
            to_consider << p
          end
        end
      end
      to_consider = to_consider - [considering]
    end
    return ancestors.include? ancestor_id 
  end
end
