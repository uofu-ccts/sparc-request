require 'rails_helper'

RSpec.describe Identity, type: :model do

  describe '.can_edit_core?' do

    let!(:identity)     { create :identity }
    let!(:organization) { create :organization }

    context 'Clinical providers' do

      context 'Identity is a clinical provider for the Organization' do

        before { create :clinical_provider, identity: identity,
                                            organization: organization }

        it 'should return true' do
          expect(identity.can_edit_core?(organization.id)).to be
        end
      end

      context 'Identity is not a clinical provider for the Organization' do

        it 'should return false' do
          expect(identity.can_edit_core?(organization.id)).to_not be
        end
      end
    end

    context 'Super users' do

      context 'Identity is a super user for the Organization' do

        before { create :super_user,  identity: identity,
                                      organization: organization }

        it 'should return true' do
          expect(identity.can_edit_core?(organization.id)).to be
        end
      end

      context 'Identity is not a super user for the Organization' do

        it 'should return false' do
          expect(identity.can_edit_core?(organization.id)).to_not be
        end
      end
    end
  end
end
