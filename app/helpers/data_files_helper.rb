module DataFilesHelper

  def authorised_data_files
    dfs=DataFile.find(:all, :include=>:asset)
    Authorization.authorize_collection("show", dfs, current_user)
  end

  def data_file_link_list data_files,sorted=true,max_length=75
    data_files = data_files.sort{|a,b| a.title<=>b.title}
    data_files=Authorization.authorize_collection("view", data_files, current_user,false)
    return "<span class='none_text'>No sops or non visible to you</span>" if data_files.empty?
    result=""
    data_files.each do |df|
      result += link_to h(truncate(df.title,:length=>max_length)), df.class.name == "DataFile" ? df : data_file_path(df.data_file, :version => df.version),:title=>h(df.title)
      result += " | " unless data_files.last==df
    end
    return result
  end

end
