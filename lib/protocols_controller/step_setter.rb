class StepSetter

  def initialize(protocol, service_request)
    @protocol = protocol
    @service_request = service_request
  end

  def set_to_service_request
    @current_step = 'return_to_service_request'
  end

  def set_to_protocol
    @protocol.populate_for_edit

    @current_step = 'protocol'
  end

  def set_to_user_details
    @protocol.populate_for_edit

    @current_step = 'user_details'
  end
end