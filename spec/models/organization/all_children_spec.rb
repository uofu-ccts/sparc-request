require 'rails_helper'

RSpec.describe Organization, type: :model do

  describe '.all_children' do

    let!(:organization) { create :organization }

    context 'children present' do

      let!(:child_organization_1) { create :organization, parent: organization }
      let!(:child_organization_2) { create :organization, parent: child_organization_1 }

      it 'should return an array of Organizations' do
        expect(organization.all_children).to eq([child_organization_1, child_organization_2])
      end
    end

    context 'children not present' do

      it 'should return an empty array' do
        expect(organization.all_children).to eq([])
      end
    end
  end
end
