require 'rails_helper'

RSpec.describe Organization, type: :model do

  describe '.children' do

    let(:organization) { create :organization }

    context 'children present' do

      let(:child_organization_1) { create :organization, parent: organization }
      let(:child_organization_2) { create :organization, parent: organization }
      let(:child_organization_3) { create :organization, parent: child_organization_1 }

      it 'should return an exclusive array of direct child Organizations' do
        expect(organization.children).to eq([child_organization_1, child_organization_2])
      end
    end

    context 'children not present' do

      it 'should return an empty array' do
        expect(organization.children).to eq([])
      end
    end
  end
end
