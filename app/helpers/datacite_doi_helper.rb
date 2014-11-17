module DataciteDoiHelper

  def generate_doi_for klass, id,  version=nil
    prefix = Seek::Config.doi_prefix.to_s + '/'
    suffix = Seek::Config.doi_suffix.to_s + '.'
    suffix << klass + '.' + id.to_s
    if version
      suffix << '.' + version.to_s
    end
    doi = prefix + suffix
    doi
  end
end