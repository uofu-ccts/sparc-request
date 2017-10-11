require 'rest-client'
require 'uri'
require 'net/http'
require 'nokogiri'
require 'net/http/digest_auth'
require 'set'

GET_FACULTY_PROFILE_PARAM = "parameter[0]"
GET_FACULTY_PROFILE_URL = ENV['GET_FACULTY_PROFILE_URL']
AUTH_USER = ENV['MBM_USER']
AUTH_PASS = ENV['MBM_KEY']

def get_affiliation affiliation
  affiliation
end

def get_mbm_record uid
  uri = URI.parse "#{GET_FACULTY_PROFILE_URL}?#{GET_FACULTY_PROFILE_PARAM}=#{uid}"
  uri.user = AUTH_USER
  uri.password = AUTH_PASS
  h = Net::HTTP.new uri.host, uri.port
  h.use_ssl = true
  h.verify_mode = OpenSSL::SSL::VERIFY_NONE # Sets the HTTPS verify mode
  # h.set_debug_output $stderr

  req = Net::HTTP::Get.new uri.request_uri

  res = h.request req

  digest_auth = Net::HTTP::DigestAuth.new
  auth = digest_auth.auth_header uri, res['www-authenticate'], 'GET'

  req = Net::HTTP::Get.new uri.request_uri
  req.add_field 'Authorization', auth

  res = h.request req

  object_hash = Hash.from_xml(res.body)['mbmroot']['facultyMember']
  object_hash
end


def inspect_mbm_record object_hash
  # puts object_hash.inspect
  puts object_hash.keys.inspect

  keys = ["personalDataCategory", "facultyMemberAppointmentsCategory", "professionalDetailsCategory", "professionalStatementsCategory", "missionActivitiesCategory"]

  keys.each do |key|
    File.open(Rails.root.join('tmp', "#{key}.json"), 'w') { |file| file.write(object_hash[key].to_json ) }
  end
end

def get_department_affiliation object_hash
  appointmentHistoryList = object_hash['facultyMemberAppointmentsCategory']['appointmentHistoryList']
  appointmentHistoryList.find do | entry |
    entry[1]['primaryflag'] == 'Y'
  end[1]
end

def create_professional_organization institution_name, college_name, department_name
  institution = ProfessionalOrganization.where(name: institution_name, org_type: 'institution').first
  if institution.nil?
    institution = ProfessionalOrganization.new
    institution.name = institution_name
    institution.org_type = "institution"
    institution.save
  end
  college = institution.children.where(name: college_name).first
  if college.nil?
    college = institution.children.create(:name => college_name, :org_type => 'college')
  end
  department = college.children.where(name: department_name).first
  if department.nil?
    department = college.children.create(:name => department_name, :org_type => 'department')
  end
  department
end

desc 'import mbm records'
task :import_mbm, [:uid] => [:environment] do |t, args|
  record = get_mbm_record args[:uid]

  department_affiliation = get_department_affiliation record

  identity = Identity.find_by_ldap_uid "#{args[:uid]}@utah.edu"

  identity.department = department_affiliation['department']

  identity.save
end

desc 'create professional organizations'
task :create_professional_organization, [:institution, :college, :department] => [:environment] do |t, args|
  create_professional_organization args[:institution], args[:college], args[:department]
end

desc 'import all mbm records'
task :import_mbm_all => [:environment] do

  uids = Identity.pluck(:ldap_uid).find_all {  |entry| /u\d+@utah\.edu/.match entry }.collect { |entry| entry[0..-10] }

  affiliation_set = Set.new

  uids.each do |uid|

    record = get_mbm_record uid

    department_affiliation = get_department_affiliation record

    identity = Identity.find_by_ldap_uid "#{args[:uid]}@utah.edu"

    affiliation = get_affiliation department_affiliation['affiliation']
    affiliation_set.add affiliation

    po = create_professional_organization 'University of Utah', affiliation, department_affiliation['department']
    identity.professional_organization = po
    
    identity.save
  end

  File.open(Rails.root.join('tmp', "affiliation_set.json"), 'w') { |file| file.write(affiliation_set.to_json ) }

end
