module CountryCodes
    @@codes = Hash.new
    File.open('config/countries.tab').each do |record|
      parts = record.split("\t")
      @@codes[parts[0]] = parts[1].strip
    end
    
    #puts "countries = " + @@codes.to_s
    
    def self.country(code)
      @@codes[code]
    end
    
    def self.code(country)
      c = nil
      @@codes.each do |key, val|
        if(country.downcase.strip == val.downcase)
          c = key.downcase
          break
        end
      end
      return c
    end
    
    def self.valid_code?(code)
      @@codes.key?(code)
    end
end