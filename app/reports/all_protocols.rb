# Copyright © 2011-2016 MUSC Foundation for Research Development
# All rights reserved.

# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following
# disclaimer in the documentation and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products
# derived from this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
# BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
# SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
# TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

class AllProtocolsReport < ReportingModule
  $canned_reports << name unless $canned_reports.include? name # update global variable so that we can populate the list, report won't show in the list without this, unless is necessary so we don't add on refresh in dev. mode

  ################## BEGIN REPORT SETUP #####################

  def self.title
    "All Protocols"
  end

  # see app/reports/test_report.rb for all options
  def default_options
    {
      "Date Range" => {:field_type => :date_range, :for => "service_requests_original_created_date", :from => "2012-03-01".to_date, :to => Date.today},
      Institution => {:field_type => :select_tag, :has_dependencies => "true"},
      Provider => {:field_type => :select_tag, :dependency => '#institution_id', :dependency_id => 'parent_id'},
      Program => {:field_type => :select_tag, :dependency => '#provider_id', :dependency_id => 'parent_id'},
      Core => {:field_type => :select_tag, :dependency => '#program_id', :dependency_id => 'parent_id'}
    }
  end

  # see app/reports/test_report.rb for all options
  def column_attrs
    attrs = {}

    attrs["Protocol ID"] = "protocol.try(:id)"
    attrs["Research Master ID"] = "protocol.try(:research_master_id)"
    attrs["Protocol Short Title"] = "protocol.try(:short_title)"
    attrs["Protocol Title"] = "protocol.try(:title)"
    attrs["Number of Requests"] = "protocol.try(:sub_service_requests).try(:count)"
    attrs["Funding Source"] = "protocol.try(:funding_source)"
    attrs["Potential Funding Source"] = "protocol.try(:potential_funding_source)"
    attrs["Sponsor Name"] = "protocol.try(:sponsor_name)"
    attrs["Financial Account"] = "protocol.try(:udak_project_number).try{prepend(' ')}"
    attrs["Study Phase"] = "protocol.try{study_phases.map(&:phase).join(', ')}"

    attrs["NCT #"] = "protocol.try(:human_subjects_info).try(:nct_number).try{prepend(' ')}"
    attrs["HR #"] = "protocol.try(:human_subjects_info).try(:hr_number).try{prepend(' ')}"
    attrs["PRO #"] = "protocol.try(:human_subjects_info).try(:pro_number).try{prepend(' ')}"
    attrs["IRB of Record"] = "protocol.try(:human_subjects_info).try(:irb_of_record)"
    attrs["IRB Expiration Date"] = "protocol.try(:human_subjects_info).try(:irb_expiration_date)"

    attrs["Primary PI Last Name"]   = "protocol.try(:primary_principal_investigator).try(:last_name)"
    attrs["Primary PI First Name"]  = "protocol.try(:primary_principal_investigator).try(:first_name)"
    attrs["Primary PI Unid"]       = "protocol.try(:primary_principal_investigator).try(:netid)"
    attrs["Primary PI Email"]       = "protocol.try(:primary_principal_investigator).try(:email)"
    attrs["Primary PI Institution"] = "protocol.try(:primary_principal_investigator).try(:professional_org_lookup, 'institution')"
    attrs["Primary PI College"]     = "protocol.try(:primary_principal_investigator).try(:professional_org_lookup, 'college')"
    attrs["Primary PI Department"]  = "protocol.try(:primary_principal_investigator).try(:professional_org_lookup, 'department')"
    attrs["Primary PI Division"]    = "protocol.try(:primary_principal_investigator).try(:professional_org_lookup, 'division')"

    attrs["Primary Coordinator(s)"] = "protocol.try(:coordinators).try(:map){|x| x.full_name}.try(:join, ', ')"
    attrs["Primary Coordinator Email(s)"] = "protocol.try(:coordinator_emails)"

    attrs["Business Manager(s)"] = "protocol.try(:billing_managers).try(:map){|x| x.full_name}.try(:join, ', ')"
    attrs["Business Manager Email(s)"] = "protocol.try(:billing_business_manager_email)"


    attrs
  end

  ################## END REPORT SETUP  #####################

  ################## BEGIN QUERY SETUP #####################
  # def table => primary table to query
  # includes, where, uniq, order, and group get passed to AR methods, http://apidock.com/rails/v3.2.13/ActiveRecord/QueryMethods
  # def includes => other tables to include
  # def where => conditions for query
  # def uniq => return distinct records
  # def group => group by this attribute (including table name is always a safe bet, ex. identities.id)
  # def order => order by these attributes (include table name is always a safe bet, ex. identities.id DESC, protocols.title ASC)
  # Primary table to query
  def table
    ServiceRequest
  end

  # Other tables to include
  def includes
    return :protocol, :sub_service_requests => :organization, :line_items => :service
  end

  # Conditions
  def where args={}
    organizations = Organization.all
    selected_organization_id = args[:core_id] || args[:program_id] || args[:provider_id] || args[:institution_id] # we want to go up the tree, service_organization_ids plural because we might have child organizations to include

    # get child organization that have services to related to them
    service_organization_ids = [selected_organization_id]
    if selected_organization_id
      org = Organization.find(selected_organization_id)
      service_organization_ids = org.all_children(organizations).map(&:id)
      service_organization_ids.flatten!
    end

    ssr_organization_ids = [args[:core_id], args[:program_id], args[:provider_id], args[:institution_id]].compact

    # get child organizations
    if not ssr_organization_ids.empty?
      org = Organization.find(selected_organization_id)
      ssr_organization_ids = [ssr_organization_ids, org.all_children(organizations).map(&:id)].flatten
    end

    if args[:service_requests_original_created_date_from] and args[:service_requests_original_created_date_to]
      created_at = args[:service_requests_original_created_date_from].to_time.strftime("%Y-%m-%d 00:00:00")..args[:service_requests_original_created_date_to].to_time.strftime("%Y-%m-%d 23:59:59")
    end

    # default values if none are provided
    service_organization_ids = Organization.all.map(&:id) if service_organization_ids.compact.empty? # use all if none are selected

    ssr_organization_ids = Organization.all.map(&:id) if ssr_organization_ids.compact.empty? # use all if none are selected

    created_at ||= self.default_options["Date Range"][:from]..self.default_options["Date Range"][:to]

    return :services => {:organization_id => service_organization_ids}, :service_requests => {:created_at => created_at}
  end

  # Return only uniq records for
  def uniq
  end

  ##################  END QUERY SETUP   #####################
end
