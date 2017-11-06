# usage:
# rake csv:users:all => export all users to ./user.csv
# rake csv:users:range start=1757 offset=1957 => export users whose id are between 1757 and 1957
# rake csv:users:last number=3   => export last 3 users
require 'csv' # according to your settings, you may or may not need this line

namespace :csv do
  namespace :users do

    desc "export all models"
    task :all => :environment do
      MODELS = [Identity, Institution, Provider, Program, Core, Service, PricingSetup, PricingMap, CatalogManager, SuperUser, ServiceProvider, ClinicalProvider]
      MODELS.each do |klass|
        export_to_csv klass.limit(1), klass
      end
    end
    desc "export all users to a csv file"
    task :identity => :environment do
      export_to_csv Identity.limit(1), Identity
    end


    task :institution => :environment do
      export_to_csv Institution.limit(1), Institution
    end

    task :service => :environment do
      export_to_csv Service.limit(1), Service
    end

    task :pricing_setup => :environment do
      export_to_csv PricingSetup.limit(1), PricingSetup
    end

    desc "export users whose id are within a range to a csv file"
    task :range => :environment do |task, args|
      export_to_csv User.where("id >= ? and id < ?", ENV['start'], ENV['offset'])
    end

    desc "export last #number users to a csv file"
    task :last => :environment do |task, arg|
      export_to_csv User.last(ENV['number'].to_i)
    end

    def export_to_csv(users, klass)
      CSV.open(Rails.root.join('doc', 'csv', "#{klass.name}.csv"), "wb") do |csv|
        csv << klass.attribute_names
        users.each do |user|
          csv << user.attributes.values
        end
      end
    end
  end
end
