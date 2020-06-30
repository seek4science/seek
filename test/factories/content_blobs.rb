# ContentBlob
# either url or data should be provided for assets
Factory.define(:content_blob) do |f|
  f.sequence(:uuid) { UUID.generate }
  f.sequence(:data) { |n| "data [#{n}]" }
  f.sequence(:original_filename) { |n| "file-#{n}" }
end

Factory.define(:min_content_blob, class: ContentBlob) do |f|
  f.sequence(:uuid) { UUID.generate }
  f.data 'Min Data'
  f.original_filename 'min file'
  f.asset { Factory(:pdf_sop, policy: Factory(:downloadable_public_policy)) }
end

Factory.define(:max_content_blob, parent: :min_content_blob) do |f|
  f.url 'http://example.com/remote.txt'
  f.file_size 8
  f.content_type 'text/plain'
end

Factory.define(:url_content_blob, parent: :content_blob) do |f|
  f.url 'http://www.abc.com'
  f.data nil
end

Factory.define(:website_content_blob, parent: :url_content_blob) do |f|
  f.content_type 'text/html'
end

Factory.define(:pdf_content_blob, parent: :content_blob) do |f|
  f.original_filename 'a_pdf_file.pdf'
  f.content_type 'application/pdf'
  f.data { File.new("#{Rails.root}/test/fixtures/files/a_pdf_file.pdf", 'rb').read }
end

# a pdf file that fails to load or be converted to text
Factory.define(:broken_pdf_content_blob, parent: :content_blob) do |f|
  f.original_filename 'broken_pdf_file.pdf'
  f.content_type 'application/pdf'
  f.data { File.new("#{Rails.root}/test/fixtures/files/broken_pdf_file.pdf", 'rb').read }
end

Factory.define(:image_content_blob, parent: :content_blob) do |f|
  f.original_filename 'image_file.png'
  f.content_type 'image/png'
  f.data { File.new("#{Rails.root}/test/fixtures/files/file_picture.png", 'rb').read }
end

Factory.define(:rightfield_content_blob, parent: :content_blob) do |f|
  f.content_type 'application/vnd.ms-excel'
  f.original_filename 'rightfield.xls'
  f.data { File.new("#{Rails.root}/test/fixtures/files/rightfield-test.xls", 'rb').read }
end

Factory.define(:spreadsheet_content_blob, parent: :content_blob) do |f|
  f.content_type 'application/vnd.ms-excel'
  f.original_filename 'test.xls'
end

Factory.define(:rightfield_annotated_content_blob, parent: :content_blob) do |f|
  f.content_type 'application/vnd.ms-excel'
  f.original_filename 'simple_populated_rightfield.xls'
  f.data { File.new("#{Rails.root}/test/fixtures/files/simple_populated_rightfield.xls", 'rb').read }
end

Factory.define(:small_test_spreadsheet_content_blob, parent: :content_blob) do |f|
  f.content_type 'application/vnd.ms-excel'
  f.original_filename 'small-test-spreadsheet.xls'
  f.data { File.new("#{Rails.root}/test/fixtures/files/small-test-spreadsheet.xls", 'rb').read }
end

Factory.define(:tiff_content_blob, parent: :content_blob) do |f|
  f.content_type 'image/tiff'
  f.original_filename 'tiff_image_test.tif'
  f.data { File.new("#{Rails.root}/test/fixtures/files/tiff_image_test.tif", 'rb').read }
end

Factory.define(:xlsx_content_blob, parent: :content_blob) do |f|
  f.content_type 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  f.original_filename 'lihua_column_index_error.xlsx'
  f.data { File.new("#{Rails.root}/test/fixtures/files/lihua_column_index_error.xlsx", 'rb').read }
end

Factory.define(:xlsm_content_blob, parent: :content_blob) do |f|
  f.content_type 'application/vnd.ms-excel.sheet.macroEnabled.12'
  f.original_filename 'test.xlsm'
  f.data { File.new("#{Rails.root}/test/fixtures/files/test.xlsm", 'rb').read }
end

Factory.define(:cronwright_model_content_blob, parent: :content_blob) do |f|
  f.content_type 'application/xml'
  f.original_filename 'cronwright.xml'
  f.data { File.new("#{Rails.root}/test/fixtures/files/cronwright.xml", 'rb').read }
end

Factory.define(:teusink_model_content_blob, parent: :content_blob) do |f|
  f.content_type 'application/xml'
  f.original_filename 'teusink.xml'
  f.data { File.new("#{Rails.root}/test/fixtures/files/Teusink.xml", 'rb').read }
end

Factory.define(:teusink_jws_model_content_blob, parent: :content_blob) do |f|
  f.original_filename 'teusink.dat'
  f.data { File.new("#{Rails.root}/test/fixtures/files/Teusink2010921171725.dat", 'rb').read }
end

Factory.define(:xgmml_content_blob, parent: :content_blob) do |f|
  f.original_filename 'cytoscape.xgmml'
  f.data { File.new("#{Rails.root}/test/fixtures/files/cytoscape.xgmml", 'rb').read }
end

Factory.define(:non_sbml_xml_content_blob, parent: :content_blob) do |f|
  f.original_filename 'non_sbml_xml.xml'
  f.data { File.new("#{Rails.root}/test/fixtures/files/non_sbml_xml.xml", 'rb').read }
end

Factory.define(:invalid_sbml_content_blob, parent: :content_blob) do |f|
  f.original_filename 'invalid_sbml_xml.xml'
  f.data { File.new("#{Rails.root}/test/fixtures/files/invalid_sbml_xml.xml", 'rb').read }
end

Factory.define(:doc_content_blob, parent: :content_blob) do |f|
  f.original_filename 'ms_word_test.doc'
  f.content_type 'application/msword'
  f.data { File.new("#{Rails.root}/test/fixtures/files/ms_word_test.doc", 'rb').read }
end

Factory.define(:docx_content_blob, parent: :content_blob) do |f|
  f.content_type 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  f.original_filename 'ms_word_test.docx'
  f.data { File.new("#{Rails.root}/test/fixtures/files/ms_word_test.docx", 'rb').read }
end

Factory.define(:odt_content_blob, parent: :content_blob) do |f|
  f.content_type 'application/vnd.oasis.opendocument.text'
  f.original_filename 'openoffice_word_test.odt'
  f.data { File.new("#{Rails.root}/test/fixtures/files/openoffice_word_test.odt", 'rb').read }
end

Factory.define(:ppt_content_blob, parent: :content_blob) do |f|
  f.content_type 'application/vnd.ms-powerpoint'
  f.original_filename 'ppt_presentation.ppt'
  f.data { File.new("#{Rails.root}/test/fixtures/files/ms_ppt_test.ppt", 'rb').read }
end

Factory.define(:pptx_content_blob, parent: :content_blob) do |f|
  f.content_type 'application/vnd.openxmlformats-officedocument.presentationml.presentation'
  f.original_filename 'ms_ppt_test.pptx'
  f.data { File.new("#{Rails.root}/test/fixtures/files/ms_ppt_test.pptx", 'rb').read }
end

Factory.define(:odp_content_blob, parent: :content_blob) do |f|
  f.content_type 'application/vnd.oasis.opendocument.presentation'
  f.original_filename 'openoffice_ppt_test.odp'
  f.data { File.new("#{Rails.root}/test/fixtures/files/openoffice_ppt_test.odp", 'rb').read }
end

Factory.define(:rtf_content_blob, parent: :content_blob) do |f|
  f.content_type 'application/rtf'
  f.original_filename 'rtf_test.rtf'
  f.data { File.new("#{Rails.root}/test/fixtures/files/rtf_test.rtf", 'rb').read }
end

Factory.define(:txt_content_blob, parent: :content_blob) do |f|
  f.content_type 'text/plain'
  f.original_filename 'txt_test.txt'
  f.data { File.new("#{Rails.root}/test/fixtures/files/txt_test.txt", 'rb').read }
end

Factory.define(:large_txt_content_blob, parent: :content_blob) do |f|
  f.content_type 'text/plain'
  f.original_filename 'large_text_file.txt'
  f.data { File.new("#{Rails.root}/test/fixtures/files/large_text_file.txt", 'rb').read }
end

Factory.define(:csv_content_blob, parent: :content_blob) do |f|
  f.content_type 'text/x-comma-separated-values'
  f.original_filename 'csv_test.csv'
  f.data { File.new("#{Rails.root}/test/fixtures/files/csv_test.csv", 'rb').read }
end

Factory.define(:tsv_content_blob, parent: :content_blob) do |f|
  f.content_type 'text/tab-separated-values'
  f.original_filename 'tsv_test.tsv'
  f.data { File.new("#{Rails.root}/test/fixtures/files/tsv_test.tsv", 'rb').read }
end

Factory.define(:json_content_blob, parent: :content_blob) do |f|
  f.content_type 'application/json'
  f.original_filename 'slideshare.json'
  f.data { File.new("#{Rails.root}/test/fixtures/files/slideshare.json", 'rb').read }
end

Factory.define(:typeless_content_blob, parent: :content_blob) do |f|
  f.content_type nil
  f.original_filename 'file_with_no_extension'
  f.data { File.new("#{Rails.root}/test/fixtures/files/file_with_no_extension", 'rb').read }
end

Factory.define(:binary_content_blob, parent: :content_blob) do |f|
  f.content_type 'application/octet-stream'
  f.original_filename 'binary.bin'
  f.data { File.new("#{Rails.root}/test/fixtures/files/little_file.txt", 'rb').read }
end

Factory.define(:sample_type_template_content_blob, parent: :content_blob) do |f|
  f.original_filename 'sample-type-example.xlsx'
  f.content_type 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  f.data { File.new("#{Rails.root}/test/fixtures/files/sample-type-example.xlsx", 'rb').read }
end

# has more than one sample sheet, and the columns are irregular with leading empty columns and gaps
Factory.define(:sample_type_template_content_blob2, parent: :content_blob) do |f|
  f.original_filename 'sample-type-example.xlsx'
  f.content_type 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  f.data { File.new("#{Rails.root}/test/fixtures/files/sample-type-example2.xls", 'rb').read }
end

Factory.define(:sample_type_populated_template_content_blob, parent: :content_blob) do |f|
  f.original_filename 'sample-type-populated.xlsx'
  f.content_type 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  f.data { File.new("#{Rails.root}/test/fixtures/files/sample-type-populated.xlsx", 'rb').read }
end

Factory.define(:sample_type_populated_template_blank_rows_content_blob, parent: :content_blob) do |f|
  f.original_filename 'sample-type-populated-blank-rows.xlsx'
  f.content_type 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  f.data { File.new("#{Rails.root}/test/fixtures/files/sample-type-populated-blank-rows.xlsx", 'rb').read }
end

Factory.define(:strain_sample_data_content_blob, parent: :content_blob) do |f|
  f.original_filename 'strain-sample-data.xlsx'
  f.content_type 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  f.data { File.new("#{Rails.root}/test/fixtures/files/strain-sample-data.xlsx", 'rb').read }
end

Factory.define(:nels_fastq_paired_template_content_blob, parent: :content_blob) do |f|
  f.original_filename 'FASTQPaired.xlsx'
  f.content_type 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  f.data { File.new("#{Rails.root}/test/fixtures/files/FASTQPaired.xlsx", 'rb').read }
end

Factory.define(:linked_samples_incomplete_content_blob, parent: :content_blob) do |f|
  f.original_filename 'FASTQPaired.xlsx'
  f.content_type 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  f.data { File.new("#{Rails.root}/test/fixtures/files/linked-samples-incomplete.xlsx", 'rb').read }
end

Factory.define(:linked_samples_complete_content_blob, parent: :content_blob) do |f|
  f.original_filename 'FASTQPaired.xlsx'
  f.content_type 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  f.data { File.new("#{Rails.root}/test/fixtures/files/linked-samples-complete.xlsx", 'rb').read }
end

Factory.define(:rightfield_master_template, parent: :content_blob) do |f|
  f.original_filename 'populated-master-template.xlsx'
  f.content_type 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  f.data { File.new("#{Rails.root}/test/fixtures/files/populated_templates/populated-master-template.xlsx", 'rb').read }
end

Factory.define(:rightfield_master_template_with_assay, parent: :content_blob) do |f|
  f.original_filename 'populated-master-template-with-assay.xlsx'
  f.content_type 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  f.data { File.new("#{Rails.root}/test/fixtures/files/populated_templates/populated-master-template-with-assay.xlsx", 'rb').read }
end

Factory.define(:rightfield_master_template_with_assay_link, parent: :content_blob) do |f|
  f.original_filename 'populated-master-template-with-assay-link.xlsx'
  f.content_type 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  f.data { File.new("#{Rails.root}/test/fixtures/files/populated_templates/populated-master-template-with-assay-link.xlsx", 'rb').read }
end

Factory.define(:rightfield_master_template_with_assay_no_study, parent: :content_blob) do |f|
  f.original_filename 'populated-master-template-with-assay-no-study.xlsx'
  f.content_type 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  f.data { File.new("#{Rails.root}/test/fixtures/files/populated_templates/populated-master-template-with-assay-no-study.xlsx", 'rb').read }
end

Factory.define(:rightfield_master_template_with_assay_no_assay_title, parent: :content_blob) do |f|
  f.original_filename 'populated-master-template-with-assay-assay-title.xlsx'
  f.content_type 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  f.data { File.new("#{Rails.root}/test/fixtures/files/populated_templates/populated-master-template-with-assay-no-assay-title.xlsx", 'rb').read }
end

Factory.define(:rightfield_master_template_with_assay_no_df_metadata, parent: :content_blob) do |f|
  f.original_filename 'populated-master-template-with-assay-no-df-title.xlsx'
  f.content_type 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  f.data { File.new("#{Rails.root}/test/fixtures/files/populated_templates/populated-master-template-with-assay-no-df-title.xlsx", 'rb').read }
end

Factory.define(:rightfield_master_template_with_assay_with_sop, parent: :content_blob) do |f|
  f.original_filename 'populated-master-template-with-assay-and-sop.xlsx'
  f.content_type 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  f.data { File.new("#{Rails.root}/test/fixtures/files/populated_templates/populated-master-template-with-assay-and-sop.xlsx", 'rb').read }
end

Factory.define(:blank_rightfield_master_template, parent: :content_blob) do |f|
  f.original_filename 'populated-master-template-with-assay-no-df-title.xlsx'
  f.content_type 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  f.data { File.new("#{Rails.root}/test/fixtures/files/blank-master-template.xlsx", 'rb').read }
end

Factory.define(:blank_content_blob, class: ContentBlob) do |f|
  f.url nil
  f.data nil
end

Factory.define(:blank_pdf_content_blob, parent: :blank_content_blob) do |f|
  f.original_filename 'a_pdf_file.pdf'
  f.content_type 'application/pdf'
end

Factory.define(:blank_xml_content_blob, parent: :blank_content_blob) do |f|
  f.original_filename 'model.xml'
  f.content_type 'application/xml'
end

Factory.define(:blank_txt_content_blob, parent: :blank_content_blob) do |f|
  f.original_filename 'a_txt_file.txt'
  f.content_type 'text/plain'
end

Factory.define(:cwl_content_blob, parent: :content_blob) do |f|
  f.original_filename 'rp2-to-rp2path.cwl'
  f.content_type 'application/x-yaml'
  f.data { File.new("#{Rails.root}/test/fixtures/files/workflows/rp2-to-rp2path.cwl", 'rb').read }
end

Factory.define(:cwl_packed_content_blob, parent: :content_blob) do |f|
  f.original_filename 'rp2-to-rp2path-packed.cwl'
  f.content_type 'application/x-yaml'
  f.data { File.new("#{Rails.root}/test/fixtures/files/workflows/rp2-to-rp2path-packed.cwl", 'rb').read }
end

Factory.define(:url_cwl_content_blob, parent: :content_blob) do |f|
  f.url 'https://www.abc.com/workflow.cwl'
  f.data nil
end

Factory.define(:blank_cwl_content_blob, parent: :blank_content_blob) do |f|
  f.original_filename 'rp2-to-rp2path.cwl'
  f.content_type 'application/x-yaml'
end

Factory.define(:existing_galaxy_ro_crate, parent: :content_blob) do |f|
  f.original_filename '1-PreProcessing.crate.zip'
  f.content_type 'application/zip'
  f.data { File.new("#{Rails.root}/test/fixtures/files/workflows/1-PreProcessing.crate.zip", 'rb').read }
end

Factory.define(:generated_galaxy_ro_crate, parent: :content_blob) do |f|
  f.original_filename 'new-workflow.basic.crate.zip'
  f.content_type 'application/zip'
  f.data { File.new("#{Rails.root}/test/fixtures/files/workflows/workflow-4-1.crate.zip", 'rb').read }
end

Factory.define(:generated_galaxy_no_diagram_ro_crate, parent: :content_blob) do |f|
  f.original_filename 'new-workflow.basic.crate.zip'
  f.content_type 'application/zip'
  f.data { File.new("#{Rails.root}/test/fixtures/files/workflows/workflow-4-1-no-diagram.crate.zip", 'rb').read }
end

Factory.define(:nf_core_ro_crate, parent: :content_blob) do |f|
  f.original_filename 'ro-crate-nf-core-ampliseq.crate.zip'
  f.content_type 'application/zip'
  f.data { File.new("#{Rails.root}/test/fixtures/files/workflows/ro-crate-nf-core-ampliseq.crate.zip", 'rb').read }
end

Factory.define(:just_cwl_ro_crate, parent: :content_blob) do |f|
  f.original_filename 'just-cwl-workflow.crate.zip'
  f.content_type 'application/zip'
  f.data { File.new("#{Rails.root}/test/fixtures/files/workflows/just-cwl-workflow.crate.zip", 'rb').read }
end
