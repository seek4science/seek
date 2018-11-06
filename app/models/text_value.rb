require_dependency File.join(Gem.loaded_specs['my_annotations'].full_gem_path,'lib','app','models','text_value')

class TextValue
  include TextValueExtensions
end
