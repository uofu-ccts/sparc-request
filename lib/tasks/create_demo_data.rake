require 'colorize'
require 'tsortablehash'
require 'faker'

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
      is_available:  true
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
      parent_id: parent_id
    )

    Provider.where({name: name, type: 'Provider' }).first
  end

  def create_program(name, parent_id)
    Program.seed(:name, :type,
      name: name,
      type: 'Program',
      order: 1,
      abbreviation: Faker::Hacker.abbreviation,
      is_available:  true,
      parent_id: parent_id
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
      parent_id: parent_id
    )

    Core.where({name: name, type: 'Core' }).first
  end

  def build_service_request
  end

  def build_project
      active_study_type_question_group = StudyTypeQuestionGroup.where({:active => true}).first_or_create
      identity = Identity.find_by_ldap_uid('jug2')
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
        funding_source: Faker::University.name,
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

      project.reload
      project

  end

  def batch_create_project(range)
    ActiveRecord::Base.transaction do
      (1..range).each do |n|
        project = build_project
        puts "#{project.title} funded by #{project.funding_source}. Primary PI is #{project.primary_pi_project_role.identity.display_name}".green
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
  desc 'create fake seed data'
  task :create_identity  => :environment do
    identity = create_fake_identity
    puts "#{identity.first_name.green} #{identity.last_name.green}"
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
  task :create_project => :environment do
    batch_create_project 100
  end

  desc 'create institution'
  task :create_institution => :environment do
    institution = create_institution Faker::University.name
    puts "#{institution.name}"
    provider = create_provider(Faker::Company.name, institution.id)
    puts "#{provider.name}"
    program = create_program(Faker::Company.name, provider.id)
    puts "#{program.name}"
    core = create_core(Faker::Company.name, program.id)
    puts "#{core.name}"
  end
end
