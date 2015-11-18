require 'rails_helper'

RSpec.describe Identity, type: :model do

  describe '.super_user_organizations' do

    let!(:identity)       { create :identity }
    let!(:organization_1) { create :organization }
    let!(:organization_2) { create :organization, parent: organization_1 }

    context 'SuperUsers not present' do

      it 'should return an empty array' do
        expect(identity.super_user_organizations).to eq([])
      end
    end

    context 'SuperUsers present' do

      before { create :super_user,  identity: identity,
                                    organization: organization_1 }

      it 'should return an array of Organizations and their children for which the Identity is a SuperUser' do
        expect(identity.super_user_organizations).to eq([organization_1, organization_2])
      end
    end
  end
end
