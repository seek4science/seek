require 'csv'

module DataFuseHelper
  def csv_to_google_data(csv)
    res = ''
    rows = CSV.parse(csv)
    rows.each_with_index do |row, i|
      if i == 0
        type = 'string'
        row.each do |entry|
          res << "data.addColumn('#{type}','#{h(entry)}');\n"
          type = 'number'
        end
        res << "data.addRows(#{rows.count - 1});\n"
      else
        row.each_with_index do |v, i2|
          v += '0' if v.end_with?('.')
          v = "'#{v}'" if i2 == 0
          res << "data.setValue(#{i - 1},#{i2},#{h(v)});\n"
        end
      end
    end
    res.html_safe
  end

  def tsv_to_flot_data(tsv)
    rows = CSV.parse(tsv, col_sep: "\t")
    rows_to_flot_data(rows)
  end

  def csv_to_flot_data(csv)
    rows = CSV.parse(csv)
    rows_to_flot_data(rows)
  end

  def rows_to_flot_data(rows)
    data = {}
    labels = []
    rows.each_with_index do |row, y|
      t = nil
      row.each_with_index do |value, x|
        if y == 0 && x != 0 # labels
          labels[x] = value
          data[value] = []
        else
          if x == 0
            t = value
          else
            data[labels[x]] << [t.to_f, value.to_f]
          end
        end
      end
    end
    result = []
    colors = %w(red blue green cyan magenta darkgreen)
    data.keys.reverse.each_with_index do |key, i|
      hash = { 'label' => key,
               'data' => data[key],
               'curvedLines' => { 'show' => true }
      }
      hash['color'] = colors[i] unless colors[i].nil?
      result << hash
    end
    result.to_json
  end
end
