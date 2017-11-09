def hash_to_rows(category, hash)
  rows = []
  hash.keys.each_with_index  { |key, index| rows.push(category: category, key: key, value: hash[key], sort_order: index + 1, concept_code: "", parent_id: "", default: "", id: "", reserved: "") }
  rows
end

def write_file(hashes, file)

  CSV.open(file, "w", write_headers: true, headers: hashes.first.keys) do |csv|
    hashes.each do |h|
      csv << h.values
    end
  end
end

desc "create permissible value csv files from constants yaml file"
task :import_constant_file, [:constant_file] => :environment do |t, args|
  constants_hash = YAML::load_file(args[:constant_file])
  old_categories_set = Set.new constants_hash.keys.collect { |key| key.singularize }
  categories = Set.new
  Dir.glob(Rails.root + 'db/seeds/permissible_values/2.0.5/*.csv') do |file|
    CSV.foreach(file, headers: true) do |row|
      # puts "#{row['category']} #{row['key']} #{row['value']}"
      categories.add(row['category'])
    end
  end
  common = old_categories_set.intersection categories
  common.to_a.collect do |category|
    file_name = Rails.root.join('tmp', 'constants', "#{category.pluralize}.csv")
    hash = constants_hash[category.pluralize]
    rows = hash_to_rows(category, hash)
    write_file(rows, file_name)
  end

  remaining = categories.subtract(old_categories_set)
  remaining.to_a.collect do |category|
    puts "copy untouched csv to temp directory: #{category.pluralize}"
    FileUtils.cp(Rails.root.join('db/seeds/permissible_values/2.0.5', "#{category.pluralize}.csv"), Rails.root.join('tmp', 'constants', "#{category.pluralize}.csv"))
  end
end
