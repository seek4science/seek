require 'fastercsv'

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

  def csv_to_flot_data csv
    data = {}
    rows = FasterCSV.parse(csv)
    labels = []
    rows.each_with_index do |row,y|
      t=nil
      row.each_with_index do |value,x|
        if y==0 && x!=0 #labels
           labels[x]=value
           data[value]=[]
        else
          if x==0
            t=value
          else
            data[labels[x]] << [t.to_f,value.to_f]
          end
        end

      end

    end
    result = []
    colors = ["red","blue","green","cyan","magenta","darkgreen"]
    data.keys.reverse.each_with_index do |key,i|
      hash = {"label"=>key,
              "data"=>data[key],
              "curvedLines"=>{"show"=>true}
      }
      hash["color"]=colors[i] unless colors[i].nil?
      result << hash
    end
    result.to_json
  end
end
