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

def format_json(port, index = [])
  CodeRay.scan(port.value(index), :json).div(:css => :class)
end

def format_xml(port, index = [])
  out = String.new
  REXML::Document.new(port.value(index)).write(out, 1)
  CodeRay.scan(out, :xml).div(:css => :class)
end

def inline_pdf(port, index = [])
  "If you do not see the PDF document displayed in the browser below, "\
  "please download it (using the button above) and load it into a PDF "\
  "reader application on your local machine.<br/>" +
    tag(:iframe, :src => port.path(index), :class => "inline_pdf")
end
