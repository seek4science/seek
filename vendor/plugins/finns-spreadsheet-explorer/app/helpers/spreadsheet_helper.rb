module SpreadsheetHelper
  
  def generate_spreadsheet_html(workbook)
    html = ""
    
    html << generate_spreadsheet_styles(workbook.styles)    
    html << generate_spreadsheet_annotations(workbook.annotations)
    
    html << "<div class=\"spreadsheet_viewer\">"
        
    #List of tabs
    first_sheet = true
    workbook.sheets.each do |sheet|
      html << "<a class=\"sheet_tab #{"selected_tab" if first_sheet}\" href=\"#\">#{sheet.name}</a>"
      first_sheet = false
    end

    html << "<div class=\"spreadsheet_container\">"
    
    first_sheet = true
    workbook.sheets.each do |sheet|
      max_col = sheet.last_col
      max_row = sheet.last_row      
      sheet_html = "<div #{"style=\"display:none\"" unless first_sheet} class=\"sheet\" id=\"spreadsheet_#{sheet.name}\">"
      sheet_html << "<table class=\"sheet #{"active_sheet" if first_sheet}\" cellspacing=\"1\">"
      
      #Alphabetical column headers
      sheet_html << "\t<tr>"
      sheet_html << "\t\t<th class=\"col_heading\"></th>"
      sheet.columns.each do |col|
        sheet_html << "\t\t<th #{col.width.nil? ? "" : "style =\"width:"+(col.width.to_f/256).to_s+"em\""} class=\"col_heading\">#{to_alpha(col.index)}</th>"
      end
      sheet_html << "\t</tr>"
      
      #Rows      
      max_row.times do |r|
        r = r+1
        row_html = ""
        row_html << "\t<tr #{(sheet[r].nil? || sheet[r].height.nil?)? "" : "style =\"height:"+sheet[r].height+"\""}>"
        row_html << "\t\t<td class=\"row_heading\">#{r}</td>" #Row index
        max_col.times do |c|
          c = c+1
          cell_html = ""
          value = ""
          style_class = ""
          formula = nil
          if sheet[r] && sheet[r][c]
            cell = sheet[r][c]
            value = cell.value
            formula = cell.formula
            style_class = " " + cell.style unless cell.style.nil?
          end
          cell_html << "\t\t<td row=\"#{r}\" col=\"#{c}\" id=\"cell_#{to_alpha(c) + r.to_s}\" #{("title=\""+ formula +"\"") if formula} class=\"cell#{style_class}\">#{value}</td>"
          row_html << cell_html
        end
        #End row
        row_html << "\t</tr>"
        sheet_html << row_html
      end
      
      #End sheet
      sheet_html << "</table>"
      sheet_html << "</div>"
      html << sheet_html
      first_sheet = false    
    end
    html << "</div>"
    html << "</div>"
    html << link_annotations(workbook.annotations)
    return html
  end
  
  private
  
  def generate_spreadsheet_styles(styles)
    html = ""
    unless styles.empty?
      html << "<style type=\"text/css\" id=\"generated_spreadsheet_styles\">\n"
      styles.each_key do |k|
        style = styles[k]
        #declare the CSS class
        html << "\t td.#{k} {\n"
        #output each CSS attribute and its value
        style.attributes.each_key do |a|
          html << "\t\t#{a}: #{style[a]};\n"
        end
        html << "\t}\n\n"
      end
    end
    html << "</style>\n"
    return html
  end
  
  def generate_spreadsheet_annotations(annotations)
    html = ""
    unless annotations.empty?
      html << "<div id=\"hidden_annotations\">\n"
      html << "<h1>HIDDEN ANNOTATIONS</h1>"
      annotations.each do |a|
        html << "\t <div class=\"annotation\" id=\"annotation_#{a.id}\">\n"
        html << "\t\t #{a.content}"
        html << "\t</div>\n\n"
      end
    end
    html << "</div>\n"
    return html
  end
  
  def link_annotations(annotations)
    html = ""
    unless annotations.empty?
      html << "<script type=\"text/javascript\">\n"
      html << "\t$(function () {\n"
      annotations.each do |a|
        html << "\t\t$(\"table.active_sheet tr\").slice(#{a.start_row},#{a.end_row+1}).each(function() {$(this).children(\"td.cell\").slice(#{a.start_column-1},#{a.end_column}).addClass(\"annotated_cell\").click(function (e) {show_annotation(#{a.id},e.pageX,e.pageY);});});"
      end
      html << "\t});\n"
      html << "</script>\n\n"
    end
    return html
  end
  
  def to_alpha(col)
    alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".split(//)    
    result = ""
    col = col-1
    while (col > -1) do
      letter = (col % 26)
      result = alphabet[letter] + result
      col = (col / 26) - 1
    end
    result
  end
end  