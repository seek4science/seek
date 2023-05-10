FactoryBot.define do
  # ContentBlob
  # either url or data should be provided for assets
  factory(:content_blob) do
    sequence(:uuid) { UUID.generate }
    sequence(:data) { |n| "data [#{n}]" }
    sequence(:original_filename) { |n| "file-#{n}" }
  end
  
  factory(:min_content_blob, class: ContentBlob) do
    sequence(:uuid) { UUID.generate }
    data { 'Min Data' }
    original_filename { 'min file' }
    asset { FactoryBot.create(:pdf_sop, policy: FactoryBot.create(:downloadable_public_policy)) }
  end
  
  factory(:max_content_blob, parent: :min_content_blob) do
    url { 'http://example.com/remote.txt' }
    file_size { 8 }
    content_type { 'text/plain' }
  end
  
  factory(:url_content_blob, parent: :content_blob) do
    url { 'http://www.abc.com' }
    data { nil }
  end
  
  factory(:website_content_blob, parent: :url_content_blob) do
    content_type { 'text/html' }
  end
  
  factory(:pdf_content_blob, parent: :content_blob) do
    original_filename { 'a_pdf_file.pdf' }
    content_type { 'application/pdf' }
    data { File.new("#{Rails.root}/test/fixtures/files/a_pdf_file.pdf", 'rb').read }
  end
  
  # a pdf file that fails to load or be converted to text
  factory(:broken_pdf_content_blob, parent: :content_blob) do
    original_filename { 'broken_pdf_file.pdf' }
    content_type { 'application/pdf' }
    data { File.new("#{Rails.root}/test/fixtures/files/broken_pdf_file.pdf", 'rb').read }
  end
  
  factory(:image_content_blob, parent: :content_blob) do
    original_filename { 'image_file.png' }
    content_type { 'image/png' }
    data { File.new("#{Rails.root}/test/fixtures/files/file_picture.png", 'rb').read }
  end
  
  factory(:rightfield_content_blob, parent: :content_blob) do
    content_type { 'application/vnd.ms-excel' }
    original_filename { 'rightfield.xls' }
    data { File.new("#{Rails.root}/test/fixtures/files/rightfield-test.xls", 'rb').read }
  end
  
  factory(:spreadsheet_content_blob, parent: :content_blob) do
    content_type { 'application/vnd.ms-excel' }
    original_filename { 'test.xls' }
  end
  
  factory(:rightfield_annotated_content_blob, parent: :content_blob) do
    content_type { 'application/vnd.ms-excel' }
    original_filename { 'simple_populated_rightfield.xls' }
    data { File.new("#{Rails.root}/test/fixtures/files/simple_populated_rightfield.xls", 'rb').read }
  end
  
  factory(:small_test_spreadsheet_content_blob, parent: :content_blob) do
    content_type { 'application/vnd.ms-excel' }
    original_filename { 'small-test-spreadsheet.xls' }
    data { File.new("#{Rails.root}/test/fixtures/files/small-test-spreadsheet.xls", 'rb').read }
  end
  
  factory(:tiff_content_blob, parent: :content_blob) do
    content_type { 'image/tiff' }
    original_filename { 'tiff_image_test.tif' }
    data { File.new("#{Rails.root}/test/fixtures/files/tiff_image_test.tif", 'rb').read }
  end
  
  factory(:xlsx_content_blob, parent: :content_blob) do
    content_type { 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' }
    original_filename { 'lihua_column_index_error.xlsx' }
    data { File.new("#{Rails.root}/test/fixtures/files/lihua_column_index_error.xlsx", 'rb').read }
  end
  
  factory(:xlsm_content_blob, parent: :content_blob) do
    content_type { 'application/vnd.ms-excel.sheet.macroEnabled.12' }
    original_filename { 'test.xlsm' }
    data { File.new("#{Rails.root}/test/fixtures/files/test.xlsm", 'rb').read }
  end
  
  factory(:cronwright_model_content_blob, parent: :content_blob) do
    content_type { 'application/xml' }
    original_filename { 'cronwright.xml' }
    data { File.new("#{Rails.root}/test/fixtures/files/cronwright.xml", 'rb').read }
  end
  
  factory(:teusink_model_content_blob, parent: :content_blob) do
    content_type { 'application/xml' }
    original_filename { 'teusink.xml' }
    data { File.new("#{Rails.root}/test/fixtures/files/Teusink.xml", 'rb').read }
  end
  
  factory(:teusink_jws_model_content_blob, parent: :content_blob) do
    original_filename { 'teusink.dat' }
    data { File.new("#{Rails.root}/test/fixtures/files/Teusink2010921171725.dat", 'rb').read }
  end
  
  factory(:xgmml_content_blob, parent: :content_blob) do
    original_filename { 'cytoscape.xgmml' }
    data { File.new("#{Rails.root}/test/fixtures/files/cytoscape.xgmml", 'rb').read }
  end
  
  factory(:non_sbml_xml_content_blob, parent: :content_blob) do
    original_filename { 'non_sbml_xml.xml' }
    data { File.new("#{Rails.root}/test/fixtures/files/non_sbml_xml.xml", 'rb').read }
  end
  
  factory(:invalid_sbml_content_blob, parent: :content_blob) do
    original_filename { 'invalid_sbml_xml.xml' }
    data { File.new("#{Rails.root}/test/fixtures/files/invalid_sbml_xml.xml", 'rb').read }
  end
  
  factory(:doc_content_blob, parent: :content_blob) do
    original_filename { 'ms_word_test.doc' }
    content_type { 'application/msword' }
    data { File.new("#{Rails.root}/test/fixtures/files/ms_word_test.doc", 'rb').read }
  end
  
  factory(:docx_content_blob, parent: :content_blob) do
    content_type { 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' }
    original_filename { 'ms_word_test.docx' }
    data { File.new("#{Rails.root}/test/fixtures/files/ms_word_test.docx", 'rb').read }
  end
  
  factory(:odt_content_blob, parent: :content_blob) do
    content_type { 'application/vnd.oasis.opendocument.text' }
    original_filename { 'openoffice_word_test.odt' }
    data { File.new("#{Rails.root}/test/fixtures/files/openoffice_word_test.odt", 'rb').read }
  end
  
  factory(:ppt_content_blob, parent: :content_blob) do
    content_type { 'application/vnd.ms-powerpoint' }
    original_filename { 'ppt_presentation.ppt' }
    data { File.new("#{Rails.root}/test/fixtures/files/ms_ppt_test.ppt", 'rb').read }
  end
  
  factory(:pptx_content_blob, parent: :content_blob) do
    content_type { 'application/vnd.openxmlformats-officedocument.presentationml.presentation' }
    original_filename { 'ms_ppt_test.pptx' }
    data { File.new("#{Rails.root}/test/fixtures/files/ms_ppt_test.pptx", 'rb').read }
  end
  
  factory(:odp_content_blob, parent: :content_blob) do
    content_type { 'application/vnd.oasis.opendocument.presentation' }
    original_filename { 'openoffice_ppt_test.odp' }
    data { File.new("#{Rails.root}/test/fixtures/files/openoffice_ppt_test.odp", 'rb').read }
  end
  
  factory(:rtf_content_blob, parent: :content_blob) do
    content_type { 'application/rtf' }
    original_filename { 'rtf_test.rtf' }
    data { File.new("#{Rails.root}/test/fixtures/files/rtf_test.rtf", 'rb').read }
  end
  
  factory(:txt_content_blob, parent: :content_blob) do
    content_type { 'text/plain' }
    original_filename { 'txt_test.txt' }
    data { File.new("#{Rails.root}/test/fixtures/files/txt_test.txt", 'rb').read }
  end
  
  factory(:large_txt_content_blob, parent: :content_blob) do
    content_type { 'text/plain' }
    original_filename { 'large_text_file.txt' }
    data { File.new("#{Rails.root}/test/fixtures/files/large_text_file.txt", 'rb').read }
  end
  
  factory(:csv_content_blob, parent: :content_blob) do
    content_type { 'text/x-comma-separated-values' }
    original_filename { 'csv_test.csv' }
    data { File.new("#{Rails.root}/test/fixtures/files/csv_test.csv", 'rb').read }
  end
  
  factory(:tsv_content_blob, parent: :content_blob) do
    content_type { 'text/tab-separated-values' }
    original_filename { 'tsv_test.tsv' }
    data { File.new("#{Rails.root}/test/fixtures/files/tsv_test.tsv", 'rb').read }
  end
  
  factory(:json_content_blob, parent: :content_blob) do
    content_type { 'application/json' }
    original_filename { 'slideshare.json' }
    data { File.new("#{Rails.root}/test/fixtures/files/slideshare.json", 'rb').read }
  end
  
  factory(:typeless_content_blob, parent: :content_blob) do
    content_type { nil }
    original_filename { 'file_with_no_extension' }
    data { File.new("#{Rails.root}/test/fixtures/files/file_with_no_extension", 'rb').read }
  end
  
  factory(:binary_content_blob, parent: :content_blob) do
    content_type { 'application/octet-stream' }
    original_filename { 'binary.bin' }
    data { File.new("#{Rails.root}/test/fixtures/files/little_file.txt", 'rb').read }
  end
  
  factory(:study_template_content_blob, parent: :content_blob) do
    original_filename { 'study_batch.zip' }
    content_type { 'application/zip' }
    data { File.new("#{Rails.root}/test/fixtures/files/study_batch.zip", 'rb').read }
  end
  
  factory(:sample_type_template_content_blob, parent: :content_blob) do
    original_filename { 'sample-type-example.xlsx' }
    content_type { 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' }
    data { File.new("#{Rails.root}/test/fixtures/files/sample-type-example.xlsx", 'rb').read }
  end
  
  # has more than one sample sheet, and the columns are irregular with leading empty columns and gaps
  factory(:sample_type_template_content_blob2, parent: :content_blob) do
    original_filename { 'sample-type-example.xlsx' }
    content_type { 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' }
    data { File.new("#{Rails.root}/test/fixtures/files/sample-type-example2.xls", 'rb').read }
  end
  
  factory(:sample_type_populated_template_content_blob, parent: :content_blob) do
    original_filename { 'sample-type-populated.xlsx' }
    content_type { 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' }
    data { File.new("#{Rails.root}/test/fixtures/files/sample-type-populated.xlsx", 'rb').read }
  end
  
  factory(:sample_type_populated_template_blank_rows_content_blob, parent: :content_blob) do
    original_filename { 'sample-type-populated-blank-rows.xlsx' }
    content_type { 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' }
    data { File.new("#{Rails.root}/test/fixtures/files/sample-type-populated-blank-rows.xlsx", 'rb').read }
  end
  
  factory(:strain_sample_data_content_blob, parent: :content_blob) do
    original_filename { 'strain-sample-data.xlsx' }
    content_type { 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' }
    data { File.new("#{Rails.root}/test/fixtures/files/strain-sample-data.xlsx", 'rb').read }
  end
  
  factory(:nels_fastq_paired_template_content_blob, parent: :content_blob) do
    original_filename { 'FASTQPaired.xlsx' }
    content_type { 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' }
    data { File.new("#{Rails.root}/test/fixtures/files/FASTQPaired.xlsx", 'rb').read }
  end
  
  factory(:linked_samples_incomplete_content_blob, parent: :content_blob) do
    original_filename { 'FASTQPaired.xlsx' }
    content_type { 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' }
    data { File.new("#{Rails.root}/test/fixtures/files/linked-samples-incomplete.xlsx", 'rb').read }
  end
  
  factory(:linked_samples_complete_content_blob, parent: :content_blob) do
    original_filename { 'FASTQPaired.xlsx' }
    content_type { 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' }
    data { File.new("#{Rails.root}/test/fixtures/files/linked-samples-complete.xlsx", 'rb').read }
  end
  
  factory(:rightfield_master_template, parent: :content_blob) do
    original_filename { 'populated-master-template.xlsx' }
    content_type { 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' }
    data { File.new("#{Rails.root}/test/fixtures/files/populated_templates/populated-master-template.xlsx", 'rb').read }
  end
  
  factory(:rightfield_master_template_with_assay, parent: :content_blob) do
    original_filename { 'populated-master-template-with-assay.xlsx' }
    content_type { 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' }
    data { File.new("#{Rails.root}/test/fixtures/files/populated_templates/populated-master-template-with-assay.xlsx", 'rb').read }
  end
  
  factory(:rightfield_master_template_with_assay_link, parent: :content_blob) do
    original_filename { 'populated-master-template-with-assay-link.xlsx' }
    content_type { 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' }
    data { File.new("#{Rails.root}/test/fixtures/files/populated_templates/populated-master-template-with-assay-link.xlsx", 'rb').read }
  end
  
  factory(:rightfield_master_template_with_assay_no_study, parent: :content_blob) do
    original_filename { 'populated-master-template-with-assay-no-study.xlsx' }
    content_type { 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' }
    data { File.new("#{Rails.root}/test/fixtures/files/populated_templates/populated-master-template-with-assay-no-study.xlsx", 'rb').read }
  end
  
  factory(:rightfield_master_template_with_assay_no_assay_title, parent: :content_blob) do
    original_filename { 'populated-master-template-with-assay-assay-title.xlsx' }
    content_type { 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' }
    data { File.new("#{Rails.root}/test/fixtures/files/populated_templates/populated-master-template-with-assay-no-assay-title.xlsx", 'rb').read }
  end
  
  factory(:rightfield_master_template_with_assay_no_df_metadata, parent: :content_blob) do
    original_filename { 'populated-master-template-with-assay-no-df-title.xlsx' }
    content_type { 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' }
    data { File.new("#{Rails.root}/test/fixtures/files/populated_templates/populated-master-template-with-assay-no-df-title.xlsx", 'rb').read }
  end
  
  factory(:rightfield_master_template_with_assay_with_sop, parent: :content_blob) do
    original_filename { 'populated-master-template-with-assay-and-sop.xlsx' }
    content_type { 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' }
    data { File.new("#{Rails.root}/test/fixtures/files/populated_templates/populated-master-template-with-assay-and-sop.xlsx", 'rb').read }
  end
  
  factory(:blank_rightfield_master_template, parent: :content_blob) do
    original_filename { 'populated-master-template-with-assay-no-df-title.xlsx' }
    content_type { 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' }
    data { File.new("#{Rails.root}/test/fixtures/files/blank-master-template.xlsx", 'rb').read }
  end
  
  factory(:blank_content_blob, class: ContentBlob) do
    url { nil }
    data { nil }
  end
  
  factory(:blank_pdf_content_blob, parent: :blank_content_blob) do
    original_filename { 'a_pdf_file.pdf' }
    content_type { 'application/pdf' }
  end
  
  factory(:blank_xml_content_blob, parent: :blank_content_blob) do
    original_filename { 'model.xml' }
    content_type { 'application/xml' }
  end
  
  factory(:blank_txt_content_blob, parent: :blank_content_blob) do
    original_filename { 'a_txt_file.txt' }
    content_type { 'text/plain' }
  end
  
  factory(:cwl_content_blob, parent: :content_blob) do
    original_filename { 'rp2-to-rp2path.cwl' }
    content_type { 'application/x-yaml' }
    data { File.new("#{Rails.root}/test/fixtures/files/workflows/rp2/workflows/rp2-to-rp2path.cwl", 'rb').read }
  end
  
  factory(:cwl_packed_content_blob, parent: :content_blob) do
    original_filename { 'rp2-to-rp2path-packed.cwl' }
    content_type { 'application/x-yaml' }
    data { File.new("#{Rails.root}/test/fixtures/files/workflows/rp2-to-rp2path-packed.cwl", 'rb').read }
  end
  
  factory(:url_cwl_content_blob, parent: :content_blob) do
    original_filename { 'rp2-to-rp2path.cwl' }
    url { 'https://www.abc.com/workflow.cwl' }
    data { nil }
  end
  
  factory(:blank_cwl_content_blob, parent: :blank_content_blob) do
    original_filename { 'rp2-to-rp2path.cwl' }
    content_type { 'application/x-yaml' }
  end
  
  factory(:existing_galaxy_ro_crate, parent: :content_blob) do
    original_filename { '1-PreProcessing.crate.zip' }
    content_type { 'application/zip' }
    data { File.new("#{Rails.root}/test/fixtures/files/workflows/1-PreProcessing.crate.zip", 'rb').read }
  end
  
  factory(:generated_galaxy_ro_crate, parent: :content_blob) do
    original_filename { 'new-workflow.basic.crate.zip' }
    content_type { 'application/zip' }
    data { File.new("#{Rails.root}/test/fixtures/files/workflows/workflow-4-1.crate.zip", 'rb').read }
  end
  
  factory(:generated_galaxy_no_diagram_ro_crate, parent: :content_blob) do
    original_filename { 'new-workflow.basic.crate.zip' }
    content_type { 'application/zip' }
    data { File.new("#{Rails.root}/test/fixtures/files/workflows/workflow-4-1-no-diagram.crate.zip", 'rb').read }
  end
  
  factory(:nf_core_ro_crate, parent: :content_blob) do
    original_filename { 'ro-crate-nf-core-ampliseq.crate.zip' }
    content_type { 'application/zip' }
    data { File.new("#{Rails.root}/test/fixtures/files/workflows/ro-crate-nf-core-ampliseq.crate.zip", 'rb').read }
  end
  
  factory(:just_cwl_ro_crate, parent: :content_blob) do
    original_filename { 'just-cwl-workflow.crate.zip' }
    content_type { 'application/zip' }
    data { File.new("#{Rails.root}/test/fixtures/files/workflows/just-cwl-workflow.crate.zip", 'rb').read }
  end
  
  factory(:fully_remote_ro_crate, parent: :content_blob) do
    original_filename { 'all_remote.crate.zip' }
    content_type { 'application/zip' }
    data { File.new("#{Rails.root}/test/fixtures/files/workflows/all_remote.crate.zip", 'rb').read }
  end
  
  factory(:ro_crate_with_tests, parent: :content_blob) do
    original_filename { 'ro_crate_with_tests.crate.zip' }
    content_type { 'application/zip' }
    data { File.new("#{Rails.root}/test/fixtures/files/workflows/ro-crate-with-tests.crate.zip", 'rb').read }
  end
  
  factory(:xlsx_population_content_blob, parent: :content_blob) do
    content_type { 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' }
    original_filename { 'population.xlsx' }
    data { File.new("#{Rails.root}/test/fixtures/files/population.xlsx", 'rb').read }
  end
  
  factory(:csv_population_content_blob, parent: :content_blob) do
    content_type { 'text/csv' }
    original_filename { 'population.csv' }
    data { File.new("#{Rails.root}/test/fixtures/files/population.csv", 'rb').read }
  end
  
  factory(:tsv_population_content_blob, parent: :content_blob) do
    content_type { 'text/tsv' }
    original_filename { 'population.tsv' }
    data { File.new("#{Rails.root}/test/fixtures/files/population.tsv", 'rb').read }
  end
  
  factory(:xlsx_population_no_header_content_blob, parent: :xlsx_population_content_blob) do
    original_filename { 'population_no_header.xlsx' }
    data { File.new("#{Rails.root}/test/fixtures/files/population_no_header.xlsx", 'rb').read }
  end
  
  factory(:xlsx_population_no_study_header_content_blob, parent: :xlsx_population_content_blob) do
    original_filename { 'population_no_study_header.xlsx' }
    data { File.new("#{Rails.root}/test/fixtures/files/population_no_study_header.xlsx", 'rb').read }
  end
  
  factory(:xlsx_population_no_investigation_content_blob, parent: :xlsx_population_content_blob) do
    original_filename { 'population_no_investigation.xlsx' }
    data { File.new("#{Rails.root}/test/fixtures/files/population_no_investigation.xlsx", 'rb').read }
  end
  
  factory(:xlsx_population_no_study_content_blob, parent: :xlsx_population_content_blob) do
    original_filename { 'population_no_study.xlsx' }
    data { File.new("#{Rails.root}/test/fixtures/files/population_no_study.xlsx", 'rb').read }
  end
  
  factory(:xlsx_population_just_isa, parent: :xlsx_population_content_blob) do
    original_filename { 'population_just_isa.xlsx' }
    data { File.new("#{Rails.root}/test/fixtures/files/population_just_isa.xlsx", 'rb').read }
  end
  
  factory(:spaces_ro_crate, parent: :content_blob) do
    original_filename { 'with-spaces.crate.zip' }
    content_type { 'application/zip' }
    data { File.new("#{Rails.root}/test/fixtures/files/workflows/with-spaces.crate.zip", 'rb').read }
  end
  
  factory(:dots_ro_crate, parent: :content_blob) do
    original_filename { 'with-dots.crate.zip' }
    content_type { 'application/zip' }
    data { File.new("#{Rails.root}/test/fixtures/files/workflows/with-dots.crate.zip", 'rb').read }
  end
  
  factory(:markdown_content_blob, parent: :content_blob) do
    content_type { 'text/markdown' }
    original_filename { 'README.md' }
    data { File.new("#{Rails.root}/test/fixtures/files/README.md", 'rb').read }
  end
  
  factory(:jupyter_notebook_content_blob, parent: :content_blob) do
    content_type { 'application/x-ipynb+json' }
    original_filename { 'create_and_link_isa_datafile.ipynb' }
    data { File.new("#{Rails.root}/test/fixtures/files/create_and_link_isa_datafile.ipynb", 'rb').read }
  end
  
  factory(:svg_content_blob, parent: :content_blob) do
    content_type { 'image/svg+xml' }
    original_filename { 'transparent-fairdom-logo-square.svg' }
    data { File.new("#{Rails.root}/test/fixtures/files/transparent-fairdom-logo-square.svg", 'rb').read }
  end
end
