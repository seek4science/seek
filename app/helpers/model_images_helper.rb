module ModelImagesHelper
  def all_model_images_link(model_instance)
    eval("model_model_images_url(#{model_instance.id})")
  end

  def new_model_image_link(model_instance)
    eval("new_model_model_image_url(#{model_instance.id})")
  end
end
