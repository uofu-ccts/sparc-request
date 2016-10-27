# Copyright © 2011-2016 MUSC Foundation for Research Development~
# All rights reserved.~

# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:~

# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.~

# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following~
# disclaimer in the documentation and/or other materials provided with the distribution.~

# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products~
# derived from this software without specific prior written permission.~

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,~
# BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT~
# SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL~
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS~
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR~
# TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.~
require 'colorize'
require 'tsortablehash'

namespace :data do
  desc "Import institutions and services from CSV"
  task :import_institution_and_service, [:ldap_uid, :dry_run] => :environment do |t, args|

    dry_run = args[:dry_run] && args[:dry_run].strip
    is_dry_run = dry_run && (dry_run.downcase == 'yes' || dry_run.downcase == 'y')

    path = Rails.root.join('db', 'csv', 'institution.csv')
    columns = {
      'id' => 0,
      'type' => 1,
      'name' => 2,
      'order' => 3,
      'css_class' => 4,
      'description' => 5,
      'parent_id' => 6,
      'abbreviation' => 7,
      'ack_language' => 8,
      'process_ssrs' => 9,
      'is_available' => 10,
      'show_in_cwf' => 14
    }

    service_columns = {
      'id' => 0,
      'name' => 1,
      'abbreviation' => 2,
      'order' => 3,
      'description' => 4,
      'is_available' => 5,
      'service_center_cost' => 6,
      'cpt_code' => 7,
      'charge_code' => 8,
      'revenue_code' => 9,
      'organization_id' => 10,
      'send_to_epic' => 14,
      'revenue_code_range_id' => 15,
      'one_time_fee' => 16
    }

    def to_bool(s)
      return true   if s == true   || s =~ (/(true|t|yes|y|1)$/i)
      return false  if s == false  || s.blank? || s =~ (/(false|f|no|n|0)$/i)
      raise ArgumentError.new("invalid value for Boolean: \"#{s}\"")
    end

    def get_identity(username)
      if !username
        STDOUT.puts 'Enter the username for the user who will manage the created catalog:'
        username = STDIN.gets.strip
      end
      identity = Identity.where({ldap_uid: username}).first
      if identity.nil?
        identity = get_identity nil
      end
      identity
    end

    def create_institution_from_row(row, columns)
      case row[columns['type']].downcase
      when 'institution'
        institution =  Institution.where({:name => row[columns['name']]}).first_or_create
        institution.update_attributes({
          'order' => row[columns['order']],
          'css_class' => row[columns['css_class']] || '',
          'description' => row[columns['description']],
          'parent_id' => row[columns['parent_id']],
          'abbreviation' => row[columns['abbreviation']],
          'ack_language' => row[columns['ack_language']],
          'process_ssrs' => row[columns['process_ssrs']],
          'is_available' => row[columns['is_available']],
          'show_in_cwf' => row[columns['show_in_cwf']]
          })
        institution
      when 'program'
        program =  Program.where({:name => row[columns['name']]}).first_or_create
        program.update_attributes({
          'order' => row[columns['order']],
          'css_class' => row[columns['css_class']] || '',
          'description' => row[columns['description']],
          'parent_id' => row[columns['parent_id']],
          'abbreviation' => row[columns['abbreviation']],
          'ack_language' => row[columns['ack_language']],
          'process_ssrs' => row[columns['process_ssrs']],
          'is_available' => row[columns['is_available']],
          'show_in_cwf' => row[columns['show_in_cwf']]
          })
        program
      when 'provider'
        provider =  Provider.where({:name => row[columns['name']]}).first_or_create
        provider.update_attributes({
          'order' => row[columns['order']],
          'css_class' => row[columns['css_class']] || '',
          'description' => row[columns['description']],
          'parent_id' => row[columns['parent_id']],
          'abbreviation' => row[columns['abbreviation']],
          'ack_language' => row[columns['ack_language']],
          'process_ssrs' => row[columns['process_ssrs']],
          'is_available' => row[columns['is_available']],
          'show_in_cwf' => row[columns['show_in_cwf']]
          })
        provider
      when 'core'
        core =  Core.where({:name => row[columns['name']]}).first_or_create
        core.update_attributes({
          'order' => row[columns['order']],
          'css_class' => row[columns['css_class']] || '',
          'description' => row[columns['description']],
          'parent_id' => row[columns['parent_id']],
          'abbreviation' => row[columns['abbreviation']],
          'ack_language' => row[columns['ack_language']],
          'process_ssrs' => row[columns['process_ssrs']],
          'is_available' => row[columns['is_available']],
          'show_in_cwf' => row[columns['show_in_cwf']]
          })
        core
      end
    end
    institutions = Hash.new
    parents = Hash.new
    institutions_created = Hash.new
    institutions_saved = Hash.new
    CSV.foreach(path, :headers => true) do |row|
      if row[columns['name']] && row[columns['id']] && row[columns['type']]
        puts row[columns['name']]
        institutions[row[columns['id']]] = row[columns['name']]
        parents[row[columns['name']]] = row[columns['parent_id']]
        institutions_created[row[columns['name']]] = create_institution_from_row(row, columns)
      elsif !row[columns['name']] && !row[columns['id']] && !row[columns['type']]
        puts 'empty row, ignored'.blue
      else
        raise 'invalid row. row has to have both name, id and type'
      end
    end
    sorted = TsortableHash.new {|hsh, key| hsh[key] = [] }
    institutions_created.each do |key, item|
      parent_id = parents[key]
      if parent_id
        parent = institutions_created[institutions[parent_id]]
        sorted[item] << parent
      end
      names = sorted[item].map { |i| i.name}.join(' ')
      puts "#{item.name} => [ #{names} ]" unless !is_dry_run
    end
    sorted.tsort.each do |i|
      puts "saving #{i.name}".green unless !is_dry_run
      if !sorted[i].empty?
        i.update_attributes({parent_id: sorted[i][0].id})
      end
      i.save! unless is_dry_run # saving the newly created institution
      if i.type.downcase == 'institution' # if an institution is created, ask the use to input the catalog manager
        identity = get_identity(args[:ldap_uid])
        catalog_manger = CatalogManager.where({identity_id: identity.id, organization_id: i.id}).first_or_create
        catalog_manger.update_attributes({edit_historic_data: true})
        catalog_manger.save!() unless is_dry_run
      end

      if i.type.downcase == 'provider' # setup pricing setups
        i.build_subsidy_map
        unless PricingSetup.exists?(organization_id: i.id)
          default = {
            :organization_id => i.id,
            :display_date => Date.today,
            :effective_date => Date.today - 1.days,
            :federal => 100,
            :corporate => 100,
            :other => 100,
            :member => 100,
            :charge_master => false,
            :college_rate_type => 'full',
            :federal_rate_type => 'full',
            :industry_rate_type => 'full',
            :investigator_rate_type => 'full',
            :internal_rate_type => 'full',
            :foundation_rate_type => 'full'
          }
          i.pricing_setups.create! default
        end
        i.save!
      end
      institutions_saved[i.name] = i # let us save the saved instance for future reference, such as service creation
    end
    puts "----------------------------------------------"
    institutions_saved.each do |key, value|
      puts "#{key} => #{value.id}"
    end
    puts "----------------------------------------------"
    institutions.each do |key, value|
      puts "#{key} => #{value}"
    end

    # import services after importing institutions
    CSV.foreach(Rails.root.join('db', 'csv', 'service.csv'), :headers => true) do |row|
      if row[service_columns['name']] && row[service_columns['organization_id']]
        organization_name = institutions[row[service_columns['organization_id']]]
        saved_organization = institutions_saved[organization_name]
        if saved_organization.nil?
          raise "organization id is not valid: #{row.inspect}"
        end
        puts "saving service #{row[service_columns['name']]}" unless !is_dry_run
        # let us update the organization_id from the saved institution instance, and then save the service
        service = Service.where({organization_id: saved_organization.id, name: row[service_columns['name']]}).first_or_create
        service.update_attributes({
          'organization_id' => saved_organization.id,
          'name' => row[service_columns['name']],
          'abbreviation' => row[service_columns['abbreviation']],
          'order' => row[service_columns['order']],
          'description' => row[service_columns['description']],
          'is_available' => to_bool(row[service_columns['is_available']].strip),
          'service_center_cost' => row[service_columns['service_center_cost']],
          'cpt_code' => row[service_columns['cpt_code']],
          'charge_code' => row[service_columns['charge_code']],
          'revenue_code' => row[service_columns['revenue_code']],
          'send_to_epic' => row[service_columns['send_to_epic']],
          'revenue_code_range_id' => row[service_columns['revenue_code_range_id']],
          'one_time_fee' => row[service_columns['one_time_fee']]
          })
          # set up a default pricing map
          service.pricing_maps.build({
            full_rate: 1,
            federal_rate: 1,
            corporate_rate: 1,
            other_rate: 1,
            member_rate: 1,
            display_date: Date.today,
            effective_date: Date.today - 1.days,
            unit_factor: 1,
            unit_type: 'Per Extraction',
            unit_minimum: 0})
        service.save!
        puts "saved service #{service.name} => #{service.id}" unless is_dry_run
      elsif !row[service_columns['name']] && !row[service_columns['organization_id']]
        puts 'empty row, ignored'.blue
      else
        raise 'invalid row. row has to have both name, id and type'
      end
    end
  end


  desc "Import cores and services from CSV"
  task :import_cores_and_services, [:uid_domain] => :environment do |t, args|
    if args[:uid_domain]
      CSV.foreach("services.csv", :headers => true) do |row|
        # Institution	Provider	Program	Administration	Service	Service Description (1 sentence to a few paragraphs)	Order (order of service display)	Hide from users? (Y/N)	Clinical Work Fullfillment (Y/N)	Nexus (Y/N)	Display Date Pricing	Effective Date Pricing 	Rate (full)	PP or OT? PP= Per Patient, OT=One Time	PP Quantity Type	PP Units Factor	PP Quant Min	OT Quantity Type	OT Quant Min	OT Unit Type	OT Unit Factor	OT Unit Max	Related Service?	Dependancy (Name of service exactly)	Super User (please provide hawkid(s))	Service Provider(s)	Catalog Manager(s) Rights (please provide hawkid)	Submission Email (please provide email address(s))
        if row[0] and row[1] and row[2] and row[4]
          institution = Institution.where(:name => row[0]).first
          if institution
            provider = institution.providers.where(:name => row[1]).first
            if provider
              program = provider.programs.where(:name => row[2]).first
              if program
                if program.has_active_pricing_setup
                  service = nil
                  organization_id = program.id
                  if row[3]
                    core = program.cores.where(:name => row[3]).first
                    if core
                      service = core.services.where(:name => row[4]).first
                      if service
                        puts "Service["+row[4]+"] already exists in Core["+row[3].to_s+"] for Institution[" + row[0].to_s + "], Provider[" + row[1].to_s + "], and Program[" + row[2].to_s + "]"
                      else
                        organization_id = core.id
                        # create below...
                      end
                    else
                      # create core
                      core = program.cores.new(:name => row[3],
                                          :abbreviation => row[3],
                                          :order => 1,
                                        #  :organization_id => organization_id,
                                          :is_available => (row[7] == 'N' ? true : false))
                      core.tag_list.add("clinical work fulfillment") if row[8] == 'Y'
                      core.tag_list.add("ctrc") if row[9] == 'Y'
                      core.save
                      puts "Inserted: Core["+row[3].to_s+"] for Institution[" + row[0].to_s + "], Provider[" + row[1].to_s + "], and Program[" + row[2].to_s + "]"
                      if row[24]
                        uids = row[24].split(',')
                        uids.each { |uid|
                          full_uid = (uid << args[:uid_domain]).strip
                          super_user = core.super_users.new
                          super_user.identity = Identity.where(:ldap_uid => full_uid).first
                          raise "Error: super user ["+full_uid+"] not found in database" unless super_user.identity
                          if super_user.save
                            puts "Inserted: Super User["+full_uid+"] for Core["+row[3].to_s+"] "
                          else
                            puts "NOT Inserted: Super User["+full_uid+"] for Core["+row[3].to_s+"] "
                          end
                        }
                      end

                      if row[25]
                        uids = row[25].split(',')
                        uids.each { |uid|
                          full_uid = (uid << args[:uid_domain]).strip
                          service_provider = core.service_providers.new
                          service_provider.identity = Identity.where(:ldap_uid => full_uid).first
                          raise "Error: service provider ["+full_uid+"] not found in database" unless service_provider.identity
                          if service_provider.save
                            puts "Inserted: Service Provider["+full_uid+"] for Core["+row[3].to_s+"] "
                          else
                            puts "NOT Inserted: Service Provider["+full_uid+"] for Core["+row[3].to_s+"] "
                          end
                        }
                      else
                        puts "Warning: No Service Providers for Core["+row[3].to_s+"] "
                      end

                      if row[26]
                        uids = row[26].split(',')
                        uids.each { |uid|
                          full_uid = (uid << args[:uid_domain]).strip
                          catalog_manager = core.catalog_managers.new
                          catalog_manager.identity = Identity.where(:ldap_uid => full_uid).first
                          raise "Error: catalog_manager ["+full_uid+"] not found in database" unless catalog_manager.identity
                          if catalog_manager.save
                            puts "Inserted: Catalog Manager["+full_uid+"] for Core["+row[3].to_s+"] "
                          else
                            puts "NOT Inserted: Catalog Manager["+full_uid+"] for Core["+row[3].to_s+"] "
                          end
                        }
                      else
                        puts "Warning: No Catalog Managers for Core["+row[3].to_s+"] "
                      end

                      if row[27]
                        emails = row[27].split(',')
                        emails.each { |email|
                          submission_email = core.submission_emails.new
                          submission_email.email = email.strip
                          if submission_email.save
                            puts "Inserted: Submission Email["+submission_email.email+"] for Core["+row[3].to_s+"] "
                          else
                            puts "NOT Inserted: Submission Email["+submission_email.email+"] for Core["+row[3].to_s+"] "
                          end
                        }
                      end
                      organization_id = core.id
                    end
                  else
                    service = program.services.where(:name => row[4]).first
                    if service
                      puts "Service["+row[4]+"] already exists in Program[" + row[2].to_s + "] for Institution[" + row[0].to_s + "], Provider[" + row[1].to_s + "]"
                    else
                      # create below using program.id as organization_id...
                    end
                  end
                  # create new service if it doesn't already exist
                  if service.nil?
                    is_one_time_fee = (row[13] == 'OT' ? true : false)
                    service = Service.new(:name => row[4],
                                        :description => row[5],
                                        :abbreviation => row[4],
                                        :order => row[6],
                                        :organization_id => organization_id,
                                        :is_available => (row[7] == 'N' ? true : false),
                                        :one_time_fee => is_one_time_fee)

                    pricing_map = service.pricing_maps.build(:display_date => Date.strptime(row[10], "%m/%d/%y"),
                                                          :effective_date => Date.strptime(row[11], "%m/%d/%y"),
                                                          :full_rate => Service.dollars_to_cents(row[12].to_s.strip.gsub("$", "").gsub(",", "")),
                                                          :unit_factor => (is_one_time_fee ? row[20] : row[15]),
                                                          # one time fee specific fields
                                                          :units_per_qty_max => (is_one_time_fee ? row[21] : nil),
                                                          :otf_unit_type => (is_one_time_fee ? row[19] : nil), # one time fee unit type
                                                          :quantity_type => (is_one_time_fee ? row[17] : nil), # not used by per patient
                                                          :quantity_minimum => (is_one_time_fee ? row[18] : nil),
                                                          # per patient specific fields
                                                          :unit_type => (is_one_time_fee ? nil : row[14]), # per patient unit type
                                                          :unit_minimum => (is_one_time_fee ? nil : row[16]))
                    if service.save
                      # add a related service
                      if (row[22] == 'Y')
                        related_service = Service.where(name: row[23]).first
                        if related_service.blank?
                          puts "Error: Related Service" + row[23].to_s + " not found for Service[" + row[4].to_s + "] for Institution[" + row[0].to_s + "], Provider[" + row[1].to_s + "], and Program[" + row[2].to_s + "]"
                        elsif service.related_services.include? related_service
                          puts "Error: Related Service" + row[23].to_s + " already exists for Service[" + row[4].to_s + "] for Institution[" + row[0].to_s + "], Provider[" + row[1].to_s + "], and Program[" + row[2].to_s + "]"
                        else
                          service.service_relations.create :related_service_id => related_service.id, :optional => false
                          puts "Inserted: Related Service" + row[23].to_s + " for Service[" + row[4].to_s + "] for Institution[" + row[0].to_s + "], Provider[" + row[1].to_s + "], and Program[" + row[2].to_s + "]"
                        end
                      end
                      puts "Inserted: Service[" + row[4].to_s + "] for Institution[" + row[0].to_s + "], Provider[" + row[1].to_s + "], and Program[" + row[2].to_s + "]"
                      # associate Pricing Map
                      if pricing_map.save
                        puts "Inserted: Pricing Map for Service[" + row[4].to_s + "]"
                      else
                        puts "NOT Inserted: Pricing Map for Service[" + row[4].to_s + "]: "+ pricing_map.errors.full_messages.inspect
                      end
                    else
                      puts "NOT Inserted: Service[" + row[4].to_s + "] for Institution[" + row[0].to_s + "], Provider[" + row[1].to_s + "], and Program[" + row[2].to_s + "]: "+ service.errors.full_messages.inspect + pricing_map.errors.full_messages.inspect
                    end
                  end
                else
                  puts "Error: Institution[" + row[0].to_s + "], Provider[" + row[1].to_s + "], and Program[" + row[2].to_s + "]  is missing an active pricing setup"
                end
              else
                puts "Error: Institution[" + row[0].to_s + "], Provider[" + row[1].to_s + "], and Program[" + row[2].to_s + "]  NOT found"
              end
            else
              puts "Error: Institution[" + row[0].to_s + "], Provider[" + row[1].to_s + "] NOT found, and Program[" + row[2].to_s + "]"
            end
          else
            puts "Error: Institution[" + row[0].to_s + "] NOT found, Provider[" + row[1].to_s + "], and Program[" + row[2].to_s + "]"
          end
        else
          puts "Error: Institution[" + row[0].to_s + "], Provider[" + row[1].to_s + "], Program[" + row[2].to_s + "], and Service[" + row[4].to_s + "] must all be specified"
        end
      end
    else
      puts "Error UID domain must be passed in as an argument"
    end
  end
end
