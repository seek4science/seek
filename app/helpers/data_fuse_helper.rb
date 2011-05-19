module DataFuseHelper

  def csv_to_google_data csv_url
    puts "csv url = #{csv_url}"
    res = ""
    csv = open(csv_url).read
    row_count=0
    rows = FasterCSV.parse(csv)
    rows.each do |row|
      if row_count==0
        row.each do |entry|
           res << "data.addColumn('number','#{entry}');\n"
        end
        #res << "data.addRows(#{rows.count});\n"
      else
        row_values = row.join(", ").gsub(".,",",")
        res << "data.addRow([#{row_values}]);\n"
      end
      row_count+=1
    end
    res
  end
end
