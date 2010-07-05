xml.instruct! :xml
xml.tag! "workbook" do
  @workbook.sheets.each do |sheet|
    xml.tag! "sheet", {"name" => sheet.name, "hidden" => sheet.hidden?, "very_hidden" => sheet.very_hidden?} do
      sheet.rows.each do |row|
        row.cells.each do |cell|
          unless cell.nil? || cell.value.nil?
            xml.tag! "cell", cell.value, {"type" => cell.value.class.name, "row" => cell.row, "column" => cell.column}
          end
        end
      end
    end
  end
end