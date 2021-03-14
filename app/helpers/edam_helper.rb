module EdamHelper

  require 'csv'

  @@edam_table = nil

  def self.ensure_edam_table
    unless @@edam_table
      file = File.join(Rails.root, 'public', 'EDAM.csv')
      @@edam_table = CSV.parse(File.read(file), headers: true)
    end
  end

  def self.edam_table
    ensure_edam_table
    return @@edam_table
  end
  
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
end
