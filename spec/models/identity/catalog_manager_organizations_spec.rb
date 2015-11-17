require 'rails_helper'

RSpec.describe Identity, type: :model do

  describe '.catalog_manager_organizations' do

    let!(:identity)        { create :identity }
    let!(:organization_1)  { create :organization }
    let!(:organization_2)  { create :organization }
    let!(:organization_3)  { create :organization, parent: organization_2 }

    before do
      create :organization
      create :catalog_manager,  organization: organization_1,
                                identity: identity
      create :catalog_manager,  organization: organization_2,
                                identity: identity
    end

    it 'should return all Organizations for which the Identity is a catalog manager' do
      expect(identity.catalog_manager_organizations).to eq([organization_1, organization_2, organization_3])
    end
  end
end
