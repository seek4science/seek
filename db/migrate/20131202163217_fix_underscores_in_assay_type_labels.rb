class FixUnderscoresInAssayTypeLabels < ActiveRecord::Migration
  def up
    sql = "SELECT assay_type_label,technology_type_label,id FROM assays"
    records = ActiveRecord::Base.connection.select(sql)
    records.each do |record|
      id=record["id"]
      assay_type_label=record["assay_type_label"]
      tech_type_table=record["technology_type_label"]
      unless assay_type_label.nil?
        update_sql = "UPDATE assays SET assay_type_label=#{ActiveRecord::Base.connection.quote(assay_type_label.gsub("_"," "))} WHERE id=#{id}"
        begin
          ActiveRecord::Base.connection.execute(update_sql)
        rescue Exception=>e
          puts "Error [#{e.message}] running sql - #{update_sql}"
        end
      end
      unless tech_type_table.nil?
        update_sql = "UPDATE assays SET technology_type_label=#{ActiveRecord::Base.connection.quote(tech_type_table.gsub("_"," "))} WHERE id=#{id}"
        begin
          ActiveRecord::Base.connection.execute(update_sql)
        rescue Exception=>e
          puts "Error [#{e.message}] running sql - #{update_sql}"
        end
      end
    end
  end

  def down
  end
end
