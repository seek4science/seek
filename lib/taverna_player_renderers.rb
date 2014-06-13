def format_csv(output, index = [])
  row_limit = 500
  html = ''

  begin
    value = output.value(index).encode('UTF-8', 'binary', :invalid => :replace, :undef => :replace)

    csv = CSV.parse(value)
    if csv.size > (row_limit + 1)
      html << "<strong>Please note:</strong> Only the first #{row_limit} rows of the CSV are displayed here.
               To see the full document, please click the download link."
    end

    html << '<div class="csv"><table>'
    csv[0...row_limit].each do |row|
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
  rescue CSV::MalformedCSVError
    html << '<i>Malformed CSV error</i>'
  end

  raw(html)
end

def format_json(port, index = [])
  value = port.value(index).encode('UTF-8', 'binary', :invalid => :replace, :undef => :replace)

  CodeRay.scan(value, :json).div(:css => :class)
end

def format_xml(port, index = [])
  value = port.value(index).encode('UTF-8', 'binary', :invalid => :replace, :undef => :replace)

  out = String.new
  REXML::Document.new(value).write(out, 1)
  CodeRay.scan(out, :xml).div(:css => :class)
end

def inline_pdf(port, index = [])
  "If you do not see the PDF document displayed in the browser below, "\
  "please download it (using the button above) and load it into a PDF "\
  "reader application on your local machine.<br/>" +
    tag(:iframe, :src => port.path(index), :class => "inline_pdf")
end

def format_error(port, index = [])
  "This output is an error, details are below.<br/>"\
  "<pre class = \"script_example_data_box\">#{port.value(index)}</pre>"
end
