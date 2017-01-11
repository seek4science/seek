module OpenbisHelper
  def dataset_file_list_item(file)
    result = file.path
    (result + content_tag(:em){" (#{number_to_human_size(file.size)})"}).html_safe
  end
end