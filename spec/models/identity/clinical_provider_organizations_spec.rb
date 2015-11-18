require 'rails_helper'

RSpec.describe Identity, type: :model do

  describe '.clinical_provider_organizations' do

    let!(:identity)       { create :identity }
    let!(:organization_1) { create :organization }
    let!(:organization_2) { create :organization, parent: organization_1 }

    context 'ClinicalProviders not present' do

      it 'should return an empty array' do
        expect(identity.clinical_provider_organizations).to eq([])
      end
    end

    context 'ClinicalProviders present' do

      let!(:clinical_provider) { create :clinical_provider,  identity: identity,
                                                            organization: organization_1 }

      it 'should return an array of Organizations and their children for which the Identity is a ClinicalProvider' do
        expect(identity.clinical_provider_organizations).to eq([organization_1, organization_2])
      end
    end
  end
end
