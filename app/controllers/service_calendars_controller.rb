class ServiceCalendarsController < ApplicationController
  layout false
  def template
    @service_request = ServiceRequest.find session[:service_request_id]
    @page = @service_request.set_visit_page params[:page].to_i
  end

  def quantity

  end

  def billing_strategy

  end

  def pricing

  end
end
