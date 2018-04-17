module DataFilesHelper
  def authorised_data_files(projects = nil)
    authorised_assets(DataFile, projects)
  end

  def split_into_two(ahash = {})
    return [{}, {}] if ahash.nil?
    return [ahash, {}] if ahash.length < 2

    keys = ahash.keys
    half = keys.length.even? ? keys.length / 2 - 1 : keys.length / 2
    left = {}
    keys[0..half].each { |key| left[key] = ahash[key] }
    right = {}
    keys[(half + 1)..-1].each { |key| right[key] = ahash[key] }

    [left, right]
  end

  def extraction_warnings_messages_for(warnings)
    if warnings && warnings.any?
      render partial: 'data_files/multi-steps/warning_messages', locals: { warnings: warnings }
    end
  end

  def extraction_warning_message(warning)
    extra_info = warning.extra_info
    case warning.problem
    when Seek::Templates::Extract::Warnings::NO_PERMISSION
      # [0] is the action, and [1] is the class of the object
      "You do not have permission to #{extra_info[0]} the #{t(extra_info[1].name.underscore)}"
    when Seek::Templates::Extract::Warnings::NOT_A_PROJECT_MEMBER
      "You are not a member of the #{t('project')} provided, so cannot link to it."
    when Seek::Templates::Extract::Warnings::NOT_IN_DB
      "No item could be found in the database for the #{t(extra_info.name.underscore)} SEEK ID provided"
    when Seek::Templates::Extract::Warnings::ID_NOT_A_VALID_URI
      'A SEEK ID was provided which is no a valid URI'
    when Seek::Templates::Extract::Warnings::ID_NOT_MATCH_HOST
      "The SEEK ID provided for the #{t(extra_info.name.underscore)} does not match this instance of SEEK"
    when Seek::Templates::Extract::Warnings::NO_STUDY
      "You are trying to create a new #{t('assay')}, but no valid #{t('study')} has been provided"
    when Seek::Templates::Extract::Warnings::DUPLICATE_ASSAY
      dup_assay_link = link_to(h(extra_info.title), extra_info, target: :_blank)
      "You are wanting to create a new #{t('assay')}, but an existing #{t('assay')} is found with the same title and #{t('study')} (#{dup_assay_link})".html_safe
    else
      raise 'warning problem type not recognized'

    end
  end
end
