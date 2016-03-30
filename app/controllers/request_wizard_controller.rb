# Copyright © 2011 MUSC Foundation for Research Development
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

class RequestWizardController < ApplicationController

  FORM_ORDER = ["catalog", "protocol", "service_details", "service_calendar", "service_subsidy", "documents_and_notes", "review"]

  before_filter :initialize_service_request
  before_filter :find_request, except: [:go_back]
  before_filter :prepare_form_variables

  def catalog
    # THIS METHOD SHOULD PREPARE ALL NECESSARY VARIABLES FOR CATALOG PAGE ON GET
    prepare_catalog
  end

  def protocol
    # THIS METHOD SHOULD PREPARE ALL NECESSARY VARIABLES FOR PROTOCOL PAGE ON GET
    cookies.delete :current_step
    @request.update_attribute(:service_requester_id, current_user.id) if @request.service_requester_id.nil?
    
    if session[:saved_protocol_id]
      @request.protocol = Protocol.find session[:saved_protocol_id]
      session.delete :saved_protocol_id
    end

    @ctrc_services = false
    if session[:errors] and session[:errors] != []
      if session[:errors][:ctrc_services]
        @ctrc_services = true
        @ssr_id = @request.protocol.find_sub_service_request_with_ctrc(@request.id)
      end
    end
  end

  def service_details
    # THIS METHOD SHOULD PREPARE ALL NECESSARY VARIABLES FOR SERVICE DETAILS PAGE ON GET
    @request.add_or_update_arms
  end

  def service_calendar
    # THIS METHOD SHOULD PREPARE ALL NECESSARY VARIABLES FOR SERVICE CALENDAR PAGE ON GET
    #use session so we know what page to show when tabs are switched
    session[:service_calendar_pages] = params[:pages] if params[:pages]

    @request.arms.each do |arm|
      #check each ARM for line_items_visits (in other words, it's a new arm)
      if arm.line_items_visits.empty?
        #Create missing line_items_visits
        @request.per_patient_per_visit_line_items.each do |line_item|
          arm.create_line_items_visit(line_item)
        end
      else
        #Check to see if ARM has been modified...
        arm.line_items_visits.each do |liv|
          #Update subject counts under certain conditions
          if @request.status == 'first_draft' or liv.subject_count.nil? or liv.subject_count > arm.subject_count
            liv.update_attribute(:subject_count, arm.subject_count)
          end
        end
        #Arm.visit_count has benn increased, so create new visit group, and populate the visits
        if arm.visit_count > arm.visit_groups.count
          ActiveRecord::Base.transaction do
            arm.mass_create_visit_group
          end
        end
        #Arm.visit_count has been decreased, destroy visit group (and visits)
        if arm.visit_count < arm.visit_groups.count
          ActiveRecord::Base.transaction do
            arm.mass_destroy_visit_group
          end
        end
      end
    end
  end

  def service_subsidy
    # THIS METHOD SHOULD PREPARE ALL NECESSARY VARIABLES FOR SERVICE SUBSIDY PAGE ON GET
    @subsidies = []
    @request.sub_service_requests.each do |ssr|
      if ssr.subsidy
        # we already have a subsidy; add it to the list
        @subsidies << ssr.subsidy
      elsif ssr.eligible_for_subsidy?
        # we don't have a subsidy yet; add it to the list but don't save it yet
        # TODO: is it a good idea to modify this SubServiceRequest like this without saving it to the database?
        @subsidies << ssr.build_subsidy
      end
    end
    route_around_if @subsidies.empty?
  end

  def documents_and_notes
    # THIS METHOD SHOULD PREPARE ALL NECESSARY VARIABLES FOR DOCUMENT MANAGEMENT PAGE ON GET
  end

  def review
    # THIS METHOD SHOULD PREPARE ALL NECESSARY VARIABLES FOR REVIEW PAGE ON GET
    @review = true
    @protocol = @request.protocol
    @service_list = @request.service_list

    # Reset all the page numbers to 1 at the start of the review request step.
    @pages = {}
    @request.arms.each{ |arm| @pages[arm.id] = 1 }
  end

  def confirmation
    # THIS METHOD SHOULD PREPARE ALL NECESSARY VARIABLES FOR CONFIRMATION PAGE ON GET
    @protocol = @request.protocol
    update_service_request_status(@request, 'submitted')
    @service_request.ensure_ssr_ids
    @service_request.update_arm_minimum_counts

    # As the service request leaves draft, so too do the arms
    @protocol.arms.each do |arm|
      arm.update_attributes(new_with_draft: false)
      if @protocol.service_requests.map {|x| x.sub_service_requests.map {|y| y.in_work_fulfillment}}.flatten.include?(true)
        arm.populate_subjects
      end
    end
    @service_list = @request.service_list

    @request.sub_service_requests.each do |ssr|
      ssr.subsidy.update_attributes(overridden: true) if ssr.subsidy
      ssr.update_attributes(nursing_nutrition_approved: false, lab_approved: false, imaging_approved: false, committee_approved: false)
    end

    send_confirmation_notifications

    # Send a notification to Lane et al to create users in Epic.  Once
    # that has been done, one of them will click a link which calls
    # approve_epic_rights.
    if USE_EPIC
      if @protocol.selected_for_epic
        @protocol.ensure_epic_user
        if QUEUE_EPIC
          EpicQueue.create(protocol_id: @protocol.id) unless EpicQueue.where(protocol_id: @protocol.id).size == 1
        else
          @protocol.awaiting_approval_for_epic_push
          send_epic_notification_for_user_approval(@protocol)
        end
      end
    end
  end

  def obtain_research_pricing
    # THIS METHOD SHOULD PREPARE ALL NECESSARY VARIABLES FOR CONFIRMATION PAGE ON GET
    @protocol = @request.protocol
    update_service_request_status(@request, 'get_a_cost_estimate')
    @request.ensure_ssr_ids

    # As the service request leaves draft, so too do the arms
    @protocol.arms.each do |arm|
      arm.update_attributes(new_with_draft: false)
    end
    @service_list = @request.service_list

    send_confirmation_notifications
  end

  def go_back
    @location = params[:current_location]
    go_to_previous_page
  end

  def save_as_draft
    unless @sub_service_request # if we are editing a sub service request just redirect
      @request.update_status('draft', false)
      @request.ensure_ssr_ids
    end

    redirect_to USER_PORTAL_LINK
  end

  def save_and_continue
    @location = params[:current_location]
    if @request.update_attributes @request_params and page_valid? 
      go_to_next_page
    else
      redirect_to (url_for action: @location), params: @request_params
    end
  end

  private

  def find_request
    @request = ServiceRequest.find params[:id]
  end

  def prepare_form_variables
    @location = params[:action]
    @request_params = params[:service_request]
    @navigation_direction = params[:direction]
    c = YAML.load_file(Rails.root.join('config', 'navigation.yml'))[@location]
    unless c.nil?
      @step_text = c['step_text']
      @css_class = c['css_class']
    end
  end

  def page_valid?
    @request.group_valid? @location.to_sym
  end

  def go_to_next_page
    current = FORM_ORDER.index @location
    if current.present? and (current != FORM_ORDER.count-1)
      new_location = FORM_ORDER[current+1]
    else
      new_location = @location
    end

    redirect_to url_for action: new_location, direction: 'forward'
  end

  def go_to_previous_page
    current = FORM_ORDER.index @location
    if current.present? and current != 0
      new_location = FORM_ORDER[current-1]
    else
      new_location = @location
    end

    redirect_to url_for action: new_location, direction: 'backward'
  end

  def route_around_if condition
    if condition
      if @navigation_direction == 'forward'
        go_to_next_page
      elsif @navigation_direction == 'backward'
        go_to_previous_page
      end
    end
  end

  def send_confirmation_notifications
    if @request.previous_submitted_at.nil?
      send_notifications(@request, @sub_service_request)
    elsif service_request_has_changed_ssr?(@request)
      xls = render_to_string :action => 'show', :formats => [:xlsx]
      @request.sub_service_requests.each do |ssr|
        if ssr_has_changed?(@request, ssr)
          send_ssr_service_provider_notifications(@request, ssr, xls)
        end
      end
    end
  end
end

