class MoveTechTypesOverToAssay < ActiveRecord::Migration
  def up
    sql = "SELECT id, technology_type_id FROM assays;"

    records = ActiveRecord::Base.connection.select(sql)
    records.each do |record|
      assay_id = record["id"]
      technology_type_id = record["technology_type_id"]
      unless technology_type_id.nil?
        assay_sql = "select title,term_uri from technology_types where id=#{technology_type_id};"
        tech_type = ActiveRecord::Base.connection.select(assay_sql).first
        if tech_type.nil?
          puts "Unable to find assay_type with id, #{id}"
        else
          label = tech_type["title"]
          uri = tech_type["term_uri"]
          update_sql = "update assays set technology_type_label=#{ActiveRecord::Base.connection.quote(label)}, technology_type_uri=#{ActiveRecord::Base.connection.quote(uri)} where id=#{assay_id};"
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
    sql = "UPDATE assays SET technology_type_label=NULL, technology_type_uri=NULL;"
    ActiveRecord::Base.connection.execute(sql)
  end
end
