require 'rails_helper'

RSpec.describe ProtocolSaver, type: :model do
  let_there_be_lane
  let_there_be_j
  build_service_request_with_study

  describe 'saving the protocol' do

    it 'should save the protocol' do
      protocol = Protocol.first
      saver = ProtocolSaver.new(protocol, service_request)
      response = saver.save_updated_protocol
      expect(response).to eq(protocol.id)
    end

    it 'should update the service requests status' do
      service_request.update_attribute(:status, 'first_draft')
      protocol = Protocol.first
      saver = ProtocolSaver.new(protocol, service_request)
      saver.save_updated_protocol
      expect(service_request.status).to eq('draft')
    end
  end 
end