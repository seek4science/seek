module SinglePagesHelper
  include BootstrapHelper

  def sp_objects_input(element_name, existing_objects, query_url)
    obj_inpt = objects_input(element_name,
                             existing_objects,
                             :typeahead => { :query_url => query_url },
                             limit: 100,
                             class: 'form-control')

  end
end
