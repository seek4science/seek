module SpreadsheetHelper
  
  def generate_spreadsheet_html(workbook)
    html = "<div class=\"spreadsheet_viewer\">"
            
    #List of tabs
    first_sheet = true
    sheet_index = 0
    workbook.sheets.each do |sheet|
      html << "<a index=\"#{sheet_index}\" class=\"sheet_tab #{"selected_tab" if first_sheet}\" href=\"#\">#{sheet.name}</a>"
      first_sheet = false
      sheet_index += 1
    end

    html << "<div class=\"spreadsheet_container\" onselectstart=\"return false;\" >"
    
    first_sheet = true
    workbook.sheets.each do |sheet|
      max_col = sheet.last_col
      max_row = sheet.last_row      
      sheet_html = "<div #{"style=\"display:none\"" unless first_sheet} class=\"sheet #{"active_sheet" if first_sheet}\" id=\"spreadsheet_#{sheet.name}\">"
      sheet_html << "<table class=\"sheet #{"active_sheet" if first_sheet}\" cellspacing=\"1\">"
      
      #Alphabetical column headers
      sheet_html << "\t<tr>"
      sheet_html << "\t\t<th class=\"col_heading\" style=\"width:3em\"></th>"
      sheet.columns.each do |col|
        sheet_html << "\t\t<th #{col.width.nil? ? "" : "style =\"width:"+(col.width.to_f/31).to_s+"px\""} class=\"col_heading\">#{to_alpha(col.index)}</th>"
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
    return html
  end
  
  private
  
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