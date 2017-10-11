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
    keys[0..half].each { |key| left[key] = ahash[key]}
    right = {}
    keys[(half + 1)..-1].each { |key| right[key] = ahash[key]}

    [left, right]
  end
end
