def format_csv(output, index = [])
  csv = CSV.parse(output.value(index))

  html = '<div class="csv"><table>'
  csv.each do |row|
    html << '<tr>'
    row.each do |cell|
      if cell && cell.size > 50
        html << "<td>#{cell[0...50]}...</td>"
      else
        html << "<td>#{cell}</td>"
      end
    end
    html << '</tr>'
  end
  html << '</table></div>'

  raw(html)
end
