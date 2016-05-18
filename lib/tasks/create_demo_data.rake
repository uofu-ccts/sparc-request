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
end
