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

# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$(document).ready ->
  add_error = (selector, message) ->
    $(selector).parent().append("<br class='custom_error_message' /><span class='custom_error_message ui-corner-all'>#{message}</span>")
    $(selector).addClass("custom_error_field")

  remove_error = (selector) ->
    $(selector).parent().find('.custom_error_message').remove()
    $(selector).removeClass("custom_error_field")

  remove_all_errors = ->
    $('.custom_error_message').remove()
    $('.custom_error_field').removeClass('custom_error_field')

  cannot_contain_letters = (selector) ->
    $(selector).val().match(/^[0-9]\d*(\.\d+)?$/) || [null]

  validate_numbers_only = (selector) ->
    unless $(selector).val() == ''
      validated_number = cannot_contain_letters(selector)
      unless validated_number[0]
        add_error(selector, "#{$(selector).prop('display')} can only contain numbers.")
        $(selector).val('')

  validate_percentages_to_federal_percentage = (selector, federal) ->
    unless $(selector).val() == ''
      validated_number = cannot_contain_letters(selector)
      if parseFloat(validated_number[0]) < parseFloat(federal)
        add_error(selector, "#{$(selector).prop('display')} percentage must be >= to the Federal percentage.")
        $(selector).val('')


  $(document).on 'change', '.percentage_field', ->
    remove_error(this)
    unless $(this).hasClass('federal_percentage_field')
      federal_number = $(this).closest('tr').siblings('.federal_row').find('.federal_percentage_field').val()
    validate_percentages_to_federal_percentage(this, federal_number)
    validate_numbers_only(this)

  $(document).on 'change', '.federal_percentage_field', ->
    remove_error(this)
    field = $(this).closest('fieldset').find('.percentage_field')
    for percentage in $(field)
      validate_percentages_to_federal_percentage(percentage, $(this).val())
      validate_numbers_only(percentage)

  $(document).on 'change', '.unit_field, .rate_field', ->
    remove_error(this)
    validate_numbers_only(this)

  $(document).on 'click', '.apply_federal_to_all_link', ->
    federal_value = $(this).closest('tr').siblings('.federal_row').find('.federal_percentage_field').val()
    $(this).closest('tr').siblings('.corporate_row').find('.corporate_percentage_field').val(federal_value).change()
    $(this).closest('tr').siblings('.other_row').find('.other_percentage_field').val(federal_value).change()
    $(this).closest('tr').siblings('.member_row').find('.member_percentage_field').val(federal_value).change()
    remove_all_errors()

  $(document).on 'click', '.save_button', (e) ->
    e.preventDefault()
    $(this).prop('disabled', 'disabled')
    $(this).parents('form').submit()
    $('.spinner').show()

    $(document).ajaxStop ->
      $('.save_button').removeAttr('disabled')
      $('.spinner').hide()

  $(document).on 'blur', '.service_rate', ->
    $(this).formatCurrency()

  $('#fix_pricing_maps_dialog').dialog({
    title: "Fix Pricing Maps"
    closeText: ""
    autoOpen: false
    modal: true
    width: 575
    height: 200
  })

  $(document).on 'click', '.fix_pricing_maps_button', ->
    if $(this).prop("class").search("disabled_button") == -1
      $('.pricing_map_fix_spinner').show()
      button_text = $(this)
      button_text.addClass("disabled_button")
      entity_id = $('.fix_pricing_maps_entity_id').val()
      old_value = $('.fix_pricing_maps_old_value').val()
      old_value_type = $('.fix_pricing_maps_old_value_type').val()
      new_value = $('.fix_pricing_maps_new_value').val()
      data = {entity_id: entity_id, old_value: old_value, old_value_type: old_value_type, new_value: new_value}
      $.ajax({
        url: "catalog_manager/update_dates_on_pricing_maps"
        data: data
        success: (data) ->
          $('.pricing_map_fix_spinner').hide()
          button_text.removeClass("disabled_button")
          $('#fix_pricing_maps_dialog').dialog('close')
      })

  $(document).on 'click', '.dont_fix_pricing_maps_button', ->
    $('#fix_pricing_maps_dialog').dialog('close')

  $(document).on 'change', '.fix_pricing_maps_on_change', ->
    entity_name = $(this).prop('entity_name')
    $('.fix_pricing_maps_entity_id').val($(this).prop('entity_id'))
    $('.fix_pricing_maps_entity_type').val($(this).prop('entity_type'))
    $('.fix_pricing_maps_old_value').val($(this).prop('old_value'))
    $('.fix_pricing_maps_new_value').val($(this).val())

    $(this).prop('old_value', $(this).val())

    $('.fix_pricing_maps_old_value_type').val("effective_date") if $(this).prop('class').search("effective_date_hidden") > -1
    $('.fix_pricing_maps_old_value_type').val("display_date") if $(this).prop('class').search("display_date_hidden") > -1
    $('.fix_pricing_maps_dialog_content').html("The pricing maps under this entity (#{entity_name}) should be readjusted to use the date you just selected.")
    $('#fix_pricing_maps_dialog').dialog("open")
