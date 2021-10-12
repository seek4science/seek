class PublicationSerializer < ContributedResourceSerializer
  include PublicationsHelper
  attributes :title, #:publication_authors,
             :journal, :published_date,
             :doi, :pubmed_id,
             :abstract, :citation,:editor, :booktitle, :publisher, :url
  attribute :link_to_pub do
    if !object.pubmed_id.blank?
      'https://www.ncbi.nlm.nih.gov/pubmed/' + object.pubmed_id.to_s
    elsif !object.doi.blank?
      'https://doi.org/' + object.doi.to_s
    elsif !object.url.blank?
      object.url.to_s
    else
      nil
    end
  end

  attribute :publication_type do
    object.publication_type.try(:title) || 'Not specified'
  end

  attribute :authors do
    if object.publication_author_names.blank?
      []
    else
      object.publication_author_names
      end
  end

  attribute :content_blobs do
    if Seek::Config.allow_publications_fulltext
      requested_version = object # always the latest (current) version for full text pdf

      get_correct_blob_content(requested_version)
    end
  end

  def convert_content_blob_to_json(cb)
    path = polymorphic_path([cb.asset, cb])
    {
      original_filename: cb.original_filename,
      url: cb.url,
      md5sum: cb.md5sum,
      sha1sum: cb.sha1sum,
      content_type: cb.content_type,
      link: "#{base_url}#{path}",
      size: cb.file_size
    }
  end


  has_many :people
  has_many :projects
  has_many :investigations
  has_many :studies
  has_many :assays
  has_many :data_files
  has_many :models
  has_many :publications
  has_many :presentations
  has_many :events
  has_many :workflows
end
