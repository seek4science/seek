module SearchHelper
  
  def search_type_options
    ["All","People","Institutions","Projects","Sops","Experiments","Models"]
  end

  #Classifies each result item into a hash with the class name as the key.
  #
  #This is to enable the resources to be displayed in the asset tabbed listing by class
  def classify_for_tabs result_collection
    results={}

    result_collection.each do |res|
      results[res.class.name] = [] unless results[res.class.name]
      results[res.class.name] << res
    end

    return results
  end
  
end
