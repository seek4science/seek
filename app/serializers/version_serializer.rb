class VersionSerializer < BaseSerializer
  attributes :title, :description, :doi, :license,
             :revision_comments, :template_name, :is_with_sample
  def id
    object.version
  end
end