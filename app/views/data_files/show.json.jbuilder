json.extract! @data_file, :id, :version,:title, :description
if @data_file.openbis_dataset_json_details
  json.openbis_dataset @data_file.openbis_dataset_json_details
end
