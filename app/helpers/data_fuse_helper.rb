module DataFuseHelper

  def csv_to_google_data csv
    res = ""
    rows = FasterCSV.parse(csv)
    rows.each_with_index do |row,i|
      if i==0
        type='string'
        row.each do |entry|
           res << "data.addColumn('#{type}','#{entry}');\n"
           type='number'
        end
        res << "data.addRows(#{rows.count-1});\n"
      else
        row.each_with_index do |v,i2|
          v = v+"0" if v.end_with?(".")
          v = "'#{v}'" if i2==0
          res << "data.setValue(#{i-1},#{i2},#{v});\n"
        end
      end

    end
    res
  end
end
