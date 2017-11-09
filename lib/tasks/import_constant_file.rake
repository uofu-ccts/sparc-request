
def hash_to_rows(category, hash)
  rows = []
  screw = Set.new ['impact_area',  'study_type']
  if screw.include? category
    hash.keys.each_with_index  do |key, index|
      rows.push(category: category, value: hash[key], key: key, sort_order: index + 1, concept_code: "", parent_id: "", default: "", id: "", reserved: "")
    end
  else
    hash.keys.each_with_index  do |key, index|
      rows.push(category: category, value: key, key: hash[key], sort_order: index + 1, concept_code: "", parent_id: "", default: "", id: "", reserved: "")
    end
  end

  rows
end

def write_file(hashes, file)

  CSV.open(file, "w", write_headers: true, headers: hashes.first.keys) do |csv|
    hashes.each do |h|
      csv << h.values
    end
  end
end

namespace :utils do
  desc "Import permissible values from csv files and add them to the appropriate table"
  task :import_permissible_values, [:constant_filepath] => :environment do |t, args|
    puts Rails.root.join("#{args[:constant_filepath]}/*.csv")
    Dir.glob(Rails.root.join("#{args[:constant_filepath]}/*.csv")) do |file|
      puts("Importing CSV file: #{file.split('/').last}")
      keys = []
      category = nil
      CSV.foreach(file, headers: true) do |row|
        category = row['category']
        keys.push(row['key'])
      end
      old_keys_set = Set.new PermissibleValue.get_key_list(category)
      unused_set = old_keys_set.subtract Set.new keys
      puts category
      puts unused_set.to_a.inspect
      PermissibleValue.where(category: category).destroy_all()
      CSV.foreach(file, headers: true) do |row|
        PermissibleValue.create(row.to_hash)
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
end
