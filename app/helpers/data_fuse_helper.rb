module DataFuseHelper

  def csv_to_google_data csv_url
    csv = open(csv_url).read
    row_count=0
    headings=nil
    FasterCSV.parse(csv) do |row|
      if row_count==0
        headings=row

      end
      row_count+=1
    end

  end
end
