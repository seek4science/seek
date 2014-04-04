class MoveAssayTypesOverToAssay < ActiveRecord::Migration
  def up
    sql = "SELECT id, assay_type_id FROM assays;"

    records = ActiveRecord::Base.connection.select(sql)
    records.each do |record|
      assay_id = record["id"]
      assay_type_id = record["assay_type_id"]
      unless assay_type_id.nil?
        assay_sql = "select title,term_uri from assay_types where id=#{assay_type_id};"
        assay_type = ActiveRecord::Base.connection.select(assay_sql).first
        if assay_type.nil?
          puts "Unable to find assay_type with id, #{assay_type_id}"
        else
          label = assay_type["title"]
          uri = assay_type["term_uri"]
          update_sql = "update assays set assay_type_label=#{ActiveRecord::Base.connection.quote(label)}, assay_type_uri=#{ActiveRecord::Base.connection.quote(uri)} where id=#{assay_id};"
          begin
            ActiveRecord::Base.connection.execute(update_sql)
          rescue Exception=>e
            puts "Error [#{e.message}] running sql - #{update_sql}"
          end
        end
      end
    end
  end

  def down
    sql = "UPDATE assays SET assay_type_label=NULL, assay_type_uri=NULL;"
    ActiveRecord::Base.connection.execute(sql)
  end
end
