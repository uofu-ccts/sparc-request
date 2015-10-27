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
class Arm < ActiveRecord::Base

  include RemotelyNotifiable

  audited

  belongs_to :protocol

  has_many :line_items_visits, dependent: :destroy
  has_many :line_items, through: :line_items_visits
  has_many :subjects
  has_many :visit_groups, order: 'position', dependent: :destroy
  has_many :visits, through: :line_items_visits

  attr_accessible :name
  attr_accessible :visit_count
  attr_accessible :subject_count      # maximum number of subjects for any visit grouping
  attr_accessible :new_with_draft     # used for existing arm validations in sparc proper (should always be false unless in first draft)
  attr_accessible :subjects_attributes
  attr_accessible :protocol_id
  attr_accessible :minimum_visit_count
  attr_accessible :minimum_subject_count
  accepts_nested_attributes_for :subjects, allow_destroy: true

  after_save :update_liv_subject_counts

  def update_liv_subject_counts

    line_items_visits.each do |liv|
      if ['first_draft', 'draft', nil].include?(liv.line_item.service_request.status)
        liv.update_attributes(subject_count: subject_count)
      end
    end
  end

  def valid_visit_count?
    !visit_count.nil? && visit_count > 0
  end

  def valid_subject_count?
    !subject_count.nil? && subject_count > 0
  end

  def valid_name?
    !name.nil? && name.length > 0
  end

  def create_line_items_visit(line_item)
    # if visit_count is nil then set it to 1
    update_attribute(:visit_count, 1) if visit_count.nil?

    # loop until visit_groups catches up to visit_count
    while visit_groups.size < visit_count
      visit_group = visit_groups.new
      raise ActiveRecord::Rollback unless visit_group.save(validate: false)
    end

    liv = LineItemsVisit.for(self, line_item)

    liv.create_visits

    liv.update_visit_names(line_items_visits.first) if line_items_visits.count > 1
  end

  def per_patient_per_visit_line_items
    line_items_visits.each.map(&:line_item).compact
  end

  def maximum_direct_costs_per_patient(line_items_visits=self.line_items_visits)
    total = 0.0
    line_items_visits.each do |liv|
      total += liv.direct_costs_for_visit_based_service_single_subject
    end

    total
  end

  def maximum_indirect_costs_per_patient(line_items_visits=self.line_items_visits)
    if USE_INDIRECT_COST
      maximum_direct_costs_per_patient(line_items_visits) * (protocol.indirect_cost_rate.to_f / 100)
    else
      return 0
    end
  end

  def maximum_total_per_patient(line_items_visits=self.line_items_visits)
    maximum_direct_costs_per_patient(line_items_visits) + maximum_indirect_costs_per_patient(line_items_visits)
  end

  def direct_costs_for_visit_based_service(line_items_visits=self.line_items_visits)
    total = 0.0
    line_items_visits.each do |vg|
      total += vg.direct_costs_for_visit_based_service
    end

    total
  end

  def indirect_costs_for_visit_based_service(line_items_visits=self.line_items_visits)
    total = 0.0
    if USE_INDIRECT_COST
      line_items_visits.each do |vg|
        total += vg.indirect_costs_for_visit_based_service
      end
    end

    total
  end

  def total_costs_for_visit_based_service(line_items_visits=self.line_items_visits)
    direct_costs_for_visit_based_service(line_items_visits) + indirect_costs_for_visit_based_service(line_items_visits)
  end

  def add_visit(position=nil, day=nil, window_before=0, window_after=0, name='', portal=false)
    result = transaction do
      raise ActiveRecord::Rollback unless create_visit_group(position, name)
      position = position.to_i - 1 unless position.blank?

      if USE_EPIC
        raise ActiveRecord::Rollback unless update_visit_group_day(day, position, portal)

        raise ActiveRecord::Rollback unless update_visit_group_window_before(window_before, position, portal)

        raise ActiveRecord::Rollback unless update_visit_group_window_after(window_after, position, portal)
      end

      # Reload to force refresh of the visits
      reload

      self.visit_count ||= 0 # in case we import a service request with nil visit count
      self.visit_count += 1

      save
    end

    if result
      return true
    else
      reload
      return false
    end
  end

  def create_visit_group(position=nil, name='')
    visit_group = visit_groups.create(position: position, name: name)
    return false unless visit_group

    # Add visits to each line item under the service request
    line_items_visits.each do |liv|
      unless liv.add_visit(visit_group)
        errors.initialize_dup(liv.errors) # TODO: is this the right way to do this?
        return false
      end
    end

    visit_group
  end

  def mass_create_visit_group
    first = visit_groups.count
    last = self.visit_count

    # Import the visit groups
    vg_columns = [:name, :arm_id, :position]
    vg_values = []
    (last - first).times do |index|
      position = first + index + 1
      vg_values.push ["Visit #{position}", id, position]
    end
    VisitGroup.import vg_columns, vg_values, validate: true

    reload
    # Grab the ids of the visit groups that were created
    vg_ids = []
    visit_groups.each do |vg|
      vg_ids.push(vg.id) if vg.visits.count == 0
    end

    # Import the visits
    columns = [:visit_group_id, :line_items_visit_id]
    values = []
    line_items_visits.each do |liv|
      vg_ids.each do |id|
        values.push [id, liv.id]
      end
    end
    Visit.import columns, values, validate: true
    reload
  end

  def mass_destroy_visit_group
    visit_groups.where("position > #{self.visit_count}").destroy_all
  end

  def remove_visit(position)
    visit_group = visit_groups.find_by_position(position)
    if !visit_group.appointments.reject { |x| !x.completed_at? }.empty?
      errors.add(:completed_appointment, 'exists for this visit.')
      return false
    else
      update_attributes(visit_count: self.visit_count - 1)
      return visit_group.destroy
    end
  end

  def populate_subjects
    subject_difference = subject_count - subjects.count
    subject_difference.times { subjects.create } if subject_difference > 0
  end

  def set_arm_edited_flag_on_subjects
    if subjects
      subjects = Subject.where(arm_id: id)
      subjects.update_all(arm_edited: true)
    end
  end

  def update_visit_group_day(day, position, portal= false)
    position = position.blank? ? visit_groups.count - 1 : position.to_i
    before = visit_groups[position - 1] unless position == 0
    current = visit_groups[position]
    after = visit_groups[position + 1] unless position >= visit_groups.size - 1

    if portal == 'true' && USE_EPIC
      valid_day = Integer(day) rescue false
      unless valid_day
        errors.add(:invalid_day, "You've entered an invalid number for the day. Please enter a valid number.")
        return false
      end
      if !before.nil? && !before.day.nil?
        if before.day > valid_day
          errors.add(:out_of_order, 'The days are out of order. This day appears to go before the previous day.')
          return false
        end
      end

      if !after.nil? && !after.day.nil?
        if valid_day > after.day
          errors.add(:out_of_order, 'The days are out of order. This day appears to go after the next day.')
          return false
        end
      end
    end

    current.update_attributes(day: day)
  end

  def update_visit_group_window_before(window_before, position, portal = false)
    position = position.blank? ? visit_groups.count - 1 : position.to_i

    valid = Integer(window_before) rescue false
    if !valid || valid < 0
      errors.add(:invalid_window_before, "You've entered an invalid number for the before window. Please enter a positive valid number")
      return false
    end

    visit_group = visit_groups[position]

    visit_group.update_attributes(window_before: window_before)
  end

  def update_visit_group_window_after(window_after, position, portal = false)
    position = position.blank? ? visit_groups.count - 1 : position.to_i

    valid = Integer(window_after) rescue false
    if !valid || valid < 0
      errors.add(:invalid_window_after, "You've entered an invalid number for the after window. Please enter a positive valid number")
      return false
    end

    visit_group = visit_groups[position]

    visit_group.update_attributes(window_after: window_after)
  end

  def service_list
    items = line_items_visits.map do |liv|
      liv.line_item.service.one_time_fee ? nil : liv.line_item
    end.compact

    groupings = {}
    items.each do |line_item|
      service = line_item.service
      name = []
      acks = []
      last_parent = nil
      last_parent_name = nil
      found_parent = false
      service.parents.reverse_each do |parent|
        next if !parent.process_ssrs? && !found_parent
        found_parent = true
        last_parent ||= parent.id
        last_parent_name ||= parent.name
        name << parent.abbreviation
        acks << parent.ack_language unless parent.ack_language.blank?
      end
      if found_parent == false
        service.parents.reverse_each do |parent|
          name << parent.abbreviation
          acks << parent.ack_language unless parent.ack_language.blank?
        end
        last_parent = service.organization.id
        last_parent_name = service.organization.name
      end

      if groupings.include? last_parent
        g = groupings[last_parent]
        g[:services] << service
        g[:line_items] << line_item
      else
        groupings[last_parent] = { process_ssr_organization_name: last_parent_name, name: name.reverse.join(' -- '), services: [service], line_items: [line_item], acks: acks.reverse.uniq.compact }
      end
    end

    groupings
  end

  def update_minimum_counts
    update_attributes(minimum_visit_count: visit_count, minimum_subject_count: subject_count)
  end

  def default_visit_days
    visit_groups.each do |vg|
      vg.update_attribute(:day, vg.position)
    end
  end

  ### audit reporting methods ###

  def audit_label(audit)
    name
  end

  ### end audit reporting methods ###
end
