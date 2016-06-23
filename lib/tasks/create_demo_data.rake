require 'colorize'
require 'tsortablehash'
require 'faker'

module Portal
end

require "#{Rails.root}/app/helpers/portal/projects_helper"
include Portal::ProjectsHelper

$funding_source = %w(college federal foundation industry investigator internal unfunded)

namespace :demo do

  def create_identity
    Identity.seed(:ldap_uid,
    last_name:             'Glenn',
    first_name:            'Julia',
    ldap_uid:              'jug2',
    institution:           'medical_university_of_south_carolina',
    college:               'college_of_medecine',
    department:            'other',
    email:                 'glennj@musc.edu',
    credentials:           'BS,    MRA',
    catalog_overlord:      true,
    password:              'p4ssword',
    password_confirmation: 'p4ssword',
    approved:              true)

    Identity.where({:ldap_uid => 'jug2'}).first
  end

  def create_fake_identity

    ldap_uid = Faker::Internet.email
    Identity.seed(:ldap_uid,
    last_name:             Faker::Name.last_name,
    first_name:            Faker::Name.first_name,
    ldap_uid:              ldap_uid,
    institution:           Faker::University.name,
    college:               Faker::University.name,
    department:            Faker::Team.name,
    email:                 ldap_uid,
    credentials:           'BS,    MRA',
    catalog_overlord:      true,
    password:              'p4ssword',
    password_confirmation: 'p4ssword',
    approved:              true)

    Identity.where({:ldap_uid => ldap_uid}).first
  end

  def create_institution(name)
    Institution.seed(:name, :type,
      name: name,
      type: 'Institution',
      order: 1,
      abbreviation: Faker::Hacker.abbreviation,
      is_available:  true,
      description: Faker::Lorem.paragraph,
      css_class: ''
    )

    Institution.where({name: name, type: 'Institution' }).first

  end

  def create_provider(name, parent_id)
    Provider.seed(:name, :type,
      name: name,
      type: 'Provider',
      order: 1,
      abbreviation: Faker::Hacker.abbreviation,
      is_available:  true,
      parent_id: parent_id,
      description: Faker::Lorem.paragraph,
      css_class: ''
    )

    provider = Provider.where({name: name, type: 'Provider' }).first
    setup_default_pricing(provider)
    provider
  end

  def create_program(name, parent_id)
    Program.seed(:name, :type,
      name: name,
      type: 'Program',
      order: 1,
      abbreviation: Faker::Hacker.abbreviation,
      is_available:  true,
      parent_id: parent_id,
      description: Faker::Lorem.paragraph,
      css_class: ''
    )

    Program.where({name: name, type: 'Program' }).first
  end

  def create_core(name, parent_id)
    Core.seed(:name, :type,
      name: name,
      type: 'Core',
      order: 1,
      abbreviation: Faker::Hacker.abbreviation,
      is_available:  true,
      parent_id: parent_id,
      description: Faker::Lorem.paragraph,
      css_class: ''
    )

    core = Core.where({name: name, type: 'Core' }).first
    build_service(core)
    core
  end

  def create_visits(service_request)
    service_request.arms.each do |arm|
      service_request.per_patient_per_visit_line_items.each do |line_item|
        arm.create_line_items_visit(line_item)
      end
    end
  end

  def update_visits(service_request)
    service_request.arms.each do |arm|
      arm.visits.each do |visit|
        visit.update_attributes(quantity: 15, research_billing_qty: 5, insurance_billing_qty: 5, effort_billing_qty: 5, billing: Faker::Lorem.word)
      end
    end
  end

  def update_visit_groups
    vgs = VisitGroup.all
    vgs.each do |vg|
      vg.update_attributes(day: vg.position)
    end
  end

  def update_visit_service_request(service_request)
    service_request.reload
    create_visits(service_request)
    update_visits(service_request)
  end

  def build_service_request(identity, program)
    service_request = create_service_request
    project = build_project(identity.ldap_uid)
    service_request.update_attribute(:protocol_id, project.id)
    service_request.update_attribute(:service_requester_id, identity.id)
    service_request.save
    SubServiceRequest.create(
      ssr_id: "0001",
      service_request_id: service_request.id,
      organization_id: program.id,
      status: "draft"
    )
    update_visit_service_request(service_request)
    update_visit_groups
    service_request
  end

  def create_service_request
    service_request = ServiceRequest.create(
      status: 'draft'
    )

    service_request.save validate: false

    service_request
  end

  def find_protocol(identity)
    Protocol.where(archived: [true,false]).
                              joins(:project_roles).
                                where('project_roles.identity_id = ?', identity.id).
                                where('project_roles.project_rights != ?', 'none').
                              uniq.
                              sort_by { |protocol| (protocol.id || '0000') + protocol.id }.
                              reverse
  end

  def add_service_to_project(project, identity)
    puts "-------------------#{project.id}--------------------------"
    service_request = create_service_request
    service_request.update_attribute(:protocol_id, project.id)
    service_request.update_attribute(:service_requester_id, identity.id)
    service_request.save
    update_visit_service_request(service_request)
    program = chooseRandomProgram
    add_service(service_request, program)
  end

  def add_services(identity)
    projects = find_protocol(identity)
    projects.first(10).each do |project|
      add_service_to_project(project, identity)
    end
    update_visit_groups
  end

  def update_sub_service_request(service_request)
    service_request.reload
    service_request.service_list.each do |org_id, values|
      line_items = values[:line_items]
      ssr = service_request.sub_service_requests.where(organization_id: org_id.to_i).first_or_create
      unless service_request.status.nil? and !ssr.status.nil?
        ssr.update_attribute(:status, service_request.status) if ['first_draft', 'draft', nil].include?(ssr.status)
        service_request.ensure_ssr_ids unless ['first_draft', 'draft'].include?(service_request.status)
      end

      line_items.each do |li|
        li.update_attribute(:sub_service_request_id, ssr.id)
      end
    end
  end

  def add_service(service_request, program)
    program.services.first(10).each do |service|
      puts "service #{service.name}".green
      existing_service_ids = service_request.line_items.map(&:service_id)
      if existing_service_ids.include? service.id
        puts "existing services #{service.name}".red
      else
        service_request.create_line_items_for_service(
            service: service,
            optional: true,
            existing_service_ids: existing_service_ids,
            recursive_call: false)
        update_sub_service_request(service_request)
      end
    end

  end

  def build_project(ldap_uid)
      active_study_type_question_group = StudyTypeQuestionGroup.where({:active => true}).first_or_create
      identity = Identity.find_by_ldap_uid(ldap_uid)
      short_title = Faker::Lorem.word
      title = Faker::Lorem.sentence
      project = Project.create(
        type: 'Project',
        short_title: short_title,
        title: title,
        sponsor_name: Faker::Name.name,
        brief_description: Faker::Lorem.paragraph,
        start_date: DateTime.now,
        end_date: DateTime.now + 365,
        funding_source: $funding_source.sample,
        funding_status: 'funded',
        indirect_cost_rate: 50,
        study_type_question_group_id: active_study_type_question_group.id
      )

      project.save validate: false

      role = ProjectRole.create(
        protocol_id:     project.id,
        identity_id:     identity.id,
        project_rights:  "approve",
        role:            "primary-pi"
      )

      role.save
      build_arms(project)
      project.reload
      add_service_to_project(project, identity)
      project

  end

  def build_service(core)
    service = Service.create(
      name: Faker::Name.name,
      abbreviation: Faker::Hacker.abbreviation,
      order: 1,
      cpt_code: '',
      organization_id: core.id
    )

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
    service
  end

  def batch_create_service(core_name, times)
    core = Core.where({name: core_name}).first
    if !core.nil?
      ActiveRecord::Base.transaction do
        (1..times).each do |n|
          service = build_service(core)
          puts "service #{service.name} created".yellow
        end
      end
    else
      puts "No core with name #{core_name} found. Creating now....".red
      core = build_core_hierachy
      ActiveRecord::Base.transaction do
        (1..times).each do |n|
          service = build_service(core)
          puts "service #{service.name} created".yellow
        end
      end
    end

  end

  # build arms for project
  def build_arms(project)
    arm = Arm.create(
      name: Faker::Name.name,
      protocol_id: project.id,
      visit_count: 10,
      subject_count: 2
    )
    arm.save
    visit_group = VisitGroup.create(arm_id: arm.id, position: 1, day: 1)
    visit_group.save
  end

  def batch_create_project(range, ldap_uid)
    ActiveRecord::Base.transaction do
      (1..range).each do |n|
        project = build_project(ldap_uid)
        puts "#{project.title} funded by #{project.funding_source}. Primary PI is #{project.primary_pi_project_role.identity.display_name}".green
      end
    end
  end

  def batch_create_identity(times)
    ActiveRecord::Base.transaction do
      (1..times).each do |n|
        identity = create_fake_identity
        puts "#{identity.first_name.green} #{identity.last_name.green}"
      end
    end
  end

  def build_study_type_question_group(active)
    StudyTypeQuestionGroup.seed(:id,
      active: active
    )
    StudyTypeQuestionGroup.where({:active => active}).first_or_create
  end
  def build_study_type_questions(range)
    ActiveRecord::Base.transaction do
      group = build_study_type_question_group(true)
      (1..range).each do |n|
        StudyTypeQuestion.seed(:id,
          order: n,
          question: Faker::Lorem.sentence,
          friendly_id: Faker::Lorem.word,
          study_type_question_group_id: group.id
        )
      end
    end
  end

  def setup_default_pricing(i)
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

  def core_has_service(core)
    core.services.size > 0
  end

  def program_has_service(program)
    if program.services.size > 0
      return true
    end
    program.cores.each do |core|
      if core_has_service(core)
        return true
      end
    end
    return false
  end

  def chooseRandomProgram
    index = rand(Program.all.size)
    program = Program.all[index]
    if !program_has_service(program)
      program = chooseRandomProgram
    end
    if program.services.size > 0
      return program
    end
    program.cores.select do |core|
      core.services.size > 0
    end.first
  end

  def setup_default_pricing_map(service)
    # set up a default pricing map
    puts "#{service.name} has no default pricing map. set up a default pricing map".yellow
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

  end

  def ask_ldap_uid
    STDOUT.puts "What is the ldap_uid?"
    STDIN.gets.chomp
  end

  def ask_name(type)
    STDOUT.puts "What is the name of #{type}?"
    STDIN.gets.chomp
  end

  def ask_times
    STDOUT.puts "How many to create?"
    STDIN.gets.chomp
  end

  def ask_confirmation(message)
    STDOUT.puts "Do you want to #{message}?(y/N)"
    answer = STDIN.gets.chomp
    answer.downcase == 'y' || answer.downcase == 'yes'
  end

  def build_core_hierachy
    institution = create_institution Faker::University.name
    puts "#{institution.name}"
    provider = create_provider(Faker::Company.name, institution.id)
    puts "#{provider.name}".red
    program = create_program(Faker::Company.name, provider.id)
    puts "#{program.name}"
    core = create_core(Faker::Company.name, program.id)
    puts "#{core.name} provides #{core.services.first.name}".green
    service = core.services.first
    has_current_pricing_map = service.current_pricing_map rescue false
    puts "Serivce has pricing map => #{has_current_pricing_map}".yellow
    puts "Service available => #{service.is_available}"
    core
  end


  desc 'create fake seed data'
  task :create_identity  => :environment do
    identity = create_fake_identity
    puts "#{identity.first_name.green} #{identity.last_name.green}"
  end

  desc 'batch create fake seed data'
  task :batch_create_identity, [:times]  => :environment do |t, args|
    if args[:times]
      times = args[:times]
    else
      times = ask_times
    end
    batch_create_identity(times.to_i)
  end

  desc 'create study type question groups'
  task :create_study_type_question_group => :environment do
    group = build_study_type_question_group(true)
    puts "#{group.id} #{group.active}"
    group = build_study_type_question_group(false)
    puts "#{group.id} #{group.active}"

    build_study_type_questions 100

  end

  desc 'create project'
  task :batch_create_project, [:ldap_uid ,:times] => :environment do |t, args|
    if args[:ldap_uid]
      ldap_uid = args[:ldap_uid]
    else
      ldap_uid = ask_ldap_uid
    end
    if args[:times]
      times = args[:times].to_i
    else
      times = ask_times.to_i
    end
    puts "ldap_uid = #{ldap_uid}".green
    puts "Times = #{times}".red
    batch_create_project(times,ldap_uid)
  end

  desc 'batch create serivce'
  task :batch_create_service, [:name, :times] => :environment do |t, args|
    if args[:name]
      core_name = args[:name]
    else
      core_name = ask_name("Core")
    end
    if args[:times]
      times = args[:times].to_i
    else
      times = ask_times.to_i
    end
    batch_create_service(core_name, times)
  end

  desc 'create institution'
  task :create_institution => :environment do
    build_core_hierachy
  end

  desc 'find protocol'
  task :find_protocol => :environment do
    ldap_uid = ask_ldap_uid
    identity = Identity.where(ldap_uid: ldap_uid).first
    find_protocol(identity).each do |protocol|
      puts "#{protocol.id} #{protocol.title.green} #{protocol.short_title.red}"
      protocol.service_requests.each do |sr|
        sr.sub_service_requests.each do |ssr|
          puts "#{ssr.organization.name.yellow} #{pretty_program_core(ssr).light_blue}"
        end
      end
    end
  end

  desc 'add service'
  task :add_service => :environment do
    ldap_uid = ask_ldap_uid
    identity = Identity.where(ldap_uid: ldap_uid).first
    add_services(identity)
  end

  desc 'build service request'
  task :build_service_request => :environment do
    core = build_core_hierachy
    ldap_uid = ask_ldap_uid
    service_request = build_service_request(Identity.find_by_ldap_uid(ldap_uid), core)
    puts "#{service_request.service_requester.display_name} created #{service_request.protocol.title.green}. #{service_request.sub_service_requests.first.organization.name}"
  end

  desc 'setup default description'
  task :create_description => :environment do
    Program.all.each do |program|
      if program.description.blank?
        puts "build default description for program #{program.name}".yellow
        program.description = Faker::Lorem.paragraph
        program.save!
      end
    end

    Core.all.each do |program|
      if program.description.blank?
        puts "build default description for program #{program.name}".yellow
        program.description = Faker::Lorem.paragraph
        program.save!
      end
    end

    Provider.all.each do |program|
      if program.description.blank?
        puts "build default description for program #{program.name}".yellow
        program.description = Faker::Lorem.paragraph
        program.save!
      end
    end

    Institution.all.each do |program|
      if program.description.blank?
        puts "build default description for program #{program.name}".yellow
        program.description = Faker::Lorem.paragraph
        program.save!
      end
    end


  end

  desc 'create default service'
  task :setup_default_service => :environment do
    Program.all.each do |program|
      if program.services.size == 0 && program.cores.size == 0
        puts "build default service for program #{program.name}"
        build_service(program)
      end
    end

    Core.all.each do |core|
      if core.services.size == 0
        puts "build default service for core #{core.name}"
        build_service(core)
      end
    end
  end

  desc 'create default pricing setup for all programs and default pricing map for all services'
  task :setup_default_pricing => :environment do
    Program.all.each do |program|
      if !program.has_active_pricing_setup
        puts "#{program.name} has no pricing setup. Set up pricing now".yellow
        setup_default_pricing(program)
      end
    end

    Service.all.each do |service|
      has_current_pricing_map = service.current_pricing_map rescue false
      if !has_current_pricing_map
        setup_default_pricing_map(service)
      end
    end

  end

  desc 'fixing project funding source'
  task :fix_funding_source => :environment do
    Project.all.each do |project|
      project.update_attribute(:funding_source, $funding_source.sample)
      project.save
    end

  end

  desc 'choose random program that has service'
  task :choose_random_proram => :environment do
    program = chooseRandomProgram
    program.services.each do |service|
      puts "#{program.name} => #{service.name}".green
    end
  end

  desc 'fix processing ssr'
  task :fix_processing_ssrs => :environment do
    Institution.all.each do |i|
      i.update_attribute(:process_ssrs, true)
      i.save
    end
  end

  desc 'fix institution css class'
  task :fix_css_class => :environment do
    Institution.all.each do |i|
      puts "#{i.name.red} missing css class" unless i.css_class
      i.update_attribute(:css_class, '')
      i.save
    end
  end

  desc 'create default pricing map for all services'
  task :create_pricing_map => :environment do
    Service.all.each do |service|
      has_current_pricing_map = service.current_pricing_map rescue false
      if !has_current_pricing_map
        setup_default_pricing_map(service)
      end
    end

  end
end
