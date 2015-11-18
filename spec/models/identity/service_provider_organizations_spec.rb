require 'rails_helper'

RSpec.describe Identity, type: :model do

  describe '.service_provider_organizations' do

    let!(:identity)       { create :identity }
    let!(:organization_1) { create :organization }
    let!(:organization_2) { create :organization, parent: organization_1 }
    let!(:service)        { create :service }

    context 'ServiceProviders not present' do

      it 'should return an empty array' do
        expect(identity.service_provider_organizations).to eq([])
      end
    end

    context 'ServiceProviders present' do

      before { create :service_provider,  identity: identity,
                                          organization: organization_1,
                                          service: service }

      it 'should return an array of Organizations and their children for which the Identity is a ServiceProvider' do
        expect(identity.service_provider_organizations).to eq([organization_1, organization_2])
      end
    end
  end
end
