require 'colorize'
require 'tsortablehash'

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
  desc 'create fake seed data'
  task :create_identity  => :environment do
    identity = create_identity
    puts "#{identity.first_name.green} #{identity.last_name.green}"
  end
end
