module DataFilesHelper
  def authorised_data_files(projects = nil)
    authorised_assets(DataFile, projects)
  end

  def authorised_assay_assets(data_file)
    data_file.assay_assets.where(assay_id: authorised_assays.collect(&:id))
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
    when :no_permission
      # [0] is the action, and [1] is the class of the object
      "You do not have permission to #{extra_info[0]} the #{t(extra_info[1].name.underscore)}"
    when :not_a_project_member
      "You are not a member of the #{t('project')} provided, so cannot link to it."
    when :no_project
      "There was not a #{t('project')} provided, so will be using your default or left blank"
    when :not_in_db
      "No item could be found in the database for the #{t(extra_info.name.underscore)} SEEK ID provided"
    when :id_not_a_valid_uri
      'A SEEK ID was provided which is no a valid URI'
    when :id_not_match_host
      "The SEEK ID provided for the #{t(extra_info.name.underscore)} does not match this instance of SEEK"
    when :no_study
      "You are trying to create a new #{t('assay')}, but no valid #{t('study')} has been provided"
    when :duplicate_assay
      dup_assay_link = link_to(h(extra_info.title), extra_info, target: :_blank)
      "You are wanting to create a new #{t('assay')}, but an existing #{t('assay')} is found with the same title and #{t('study')} (#{dup_assay_link})".html_safe
    else
      raise 'warning problem type not recognized'

    end
  end

  def extraction_exception_message(message)
    return if message.blank?
    render partial: 'data_files/multi-steps/exception_message', object: message
  end
end
