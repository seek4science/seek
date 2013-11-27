class FixAssayTypeUrIs < ActiveRecord::Migration
  def up
    sql = "SELECT id,term_uri FROM assay_types WHERE term_uri IS NOT NULL;"
    records = ActiveRecord::Base.connection.execute(sql)

    records.each do |record|
      id = record[0]
      uri = record[1]
      uri = uri.gsub(" ","_").strip #by error, there is a dodgy uri with a space rather than an underscore in it
      uri = URI.parse(uri)

      fragment = uri.fragment.capitalize
      uri.fragment = fragment

      update_sql = "UPDATE assay_types SET term_uri='#{uri.to_s}' WHERE id=#{id};"
      begin
        ActiveRecord::Base.connection.execute(sql)
      rescue
        pp "There was a problem with executing:\n\t#{sql}"
      end
    end

  end

  def down
  end
end
