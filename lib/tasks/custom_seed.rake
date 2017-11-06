require 'colorize'
require 'seed_dump'
require 'seed-fu'
namespace :db do
  namespace :seed do
    Dir[File.join(Rails.root, 'db', 'seeds', '*.rb')].each do |filename|
      task_name = File.basename(filename, '.rb')
      desc task_name
      task task_name.intern => :environment do
        load(filename) if File.exist?(filename)
      end
    end
  end

  namespace :seed do

    def batch_params_from(records, options)
      batch_size = batch_size_from(records, options)

      count = records.count

      remainder = count % batch_size

      [((count.to_f / batch_size).ceil), batch_size, (remainder == 0 ? batch_size : remainder)]
    end

    def batch_size_from(records, options)
      if options[:batch_size].present?
        options[:batch_size].to_i
      else
        1000
      end
    end

    def value_to_s(value)
      value = case value
              when BigDecimal, IPAddr
                value.to_s
              when Date, Time, DateTime
                value.to_s(:db)
              when Range
                range_to_string(value)
              else
                value
              end

      value
    end

    def inspect_table(table_name, options)
      puts table_name.yellow
      indexes = ActiveRecord::Base.connection.indexes(table_name).map do |index|
        index.name.green + " => " + index.columns.join(" ")
      end
      puts indexes.join(" | ")
    end

    def dump_constraints(table_name)
      index = ActiveRecord::Base.connection.indexes(table_name).first
      index = index.columns.join(", ") unless index.nil?
      puts ":constraints => [#{index}]" unless index.nil?
    end

    def dump_seed_fu(model, options)
      puts "#{Rails.root}/db/fixtures/#{model.name.split('::').last.downcase}.rb".green
      puts model.name.yellow
      send :dump_constraints, model.table_name
    end

    desc 'inspect indexes for all tables'
    task :inspect_indexes, [:options] => :environment do |t, args|
      options = args[:options] || {}
      models = ActiveRecord::Base.descendants
      models = models.select do |model|
                 (model.to_s != 'ActiveRecord::SchemaMigration') && \
                  model.table_exists? && \
                  model.exists?
               end
      models.each do |model|
        # table = model.table_name
        # send :inspect_table, table, options
        send :dump_seed_fu, model, options
      end
    end

    desc 'dump records to SeedFu format'
    task :dump_seed_fu, [:options] => :environment do |t, args|
      Rails.application.eager_load!
      options = args[:options] || {}
      models_env = options['MODEL'] || options['MODELS']
      models = if models_env
                 models_env.split(',')
                           .collect {|x| x.strip.underscore.singularize.camelize.constantize }
               else
                 ActiveRecord::Base.descendants
               end

      models = models.select do |model|
                 (model.to_s != 'ActiveRecord::SchemaMigration') && \
                  model.table_exists? && \
                  model.exists?
               end

      models.each do |records|
        next if ['Audit', 'Session'].include? records.name.split('::').last
        # puts Rails.root.join('db', 'fixtures', model.name.split('::').last.downcase + '.rb')
        # puts "#{Rails.root}/db/fixtures/#{model.name.split('::').last.downcase}.rb"
        if !records.respond_to?(:arel) || records.arel.orders.blank?
          records.order("#{records.quoted_table_name}.#{records.quoted_primary_key} ASC")
        end

        path = "#{Rails.root}/db/fixtures/#{records.name.split('::').last.downcase}.rb"
        index = ActiveRecord::Base.connection.indexes(records.table_name).first
        constraints = index.columns unless index.nil?

        SeedFu::Writer.write(path, :class_name => records.name, :constraints => constraints) do |writer|
          records.all.each do |record|
            attributes = record.attributes
            ["created_at", "deleted_at", "updated_at"].each do |k|
              attributes.delete(k)
            end
            attributes = Hash[attributes.map { |k, v| [k.to_sym, value_to_s(v)]}]
            writer.add(attributes)
          end
        end
      end

    end
  end
end
