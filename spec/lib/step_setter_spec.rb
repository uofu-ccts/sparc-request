require 'rails_helper'

RSpec.describe StepSetter, type: :model do

  describe 'set to service request' do

    it 'should return the service request step' do
      protocol = create(:protocol, :without_validations)
      service_request = create(:service_request, :without_validations, protocol: protocol)

      response = StepSetter.new(protocol, service_request).set_to_service_request

      expect(response).to eq('return_to_service_request')
    end
  end

  describe 'set to protocol' do

    it 'should return the protocol step' do
      protocol = create(:protocol, :without_validations)
      service_request = create(:service_request, :without_validations, protocol: protocol)

      response = StepSetter.new(protocol, service_request).set_to_protocol

      expect(response).to eq('protocol')
    end
  end

  describe 'set to user details' do

    it 'should return the user details step' do
      protocol = create(:protocol, :without_validations)
      service_request = create(:service_request, :without_validations, protocol: protocol)

      response = StepSetter.new(protocol, service_request).set_to_user_details

      expect(response).to eq('user_details')
    end
  end
end