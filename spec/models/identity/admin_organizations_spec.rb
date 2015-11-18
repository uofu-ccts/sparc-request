require 'rails_helper'

RSpec.describe Identity, type: :model do

  describe '.admin_organizations' do

    let!(:identity)     { create :identity }
    let!(:organization) { create :organization }

    context 'Identity has no Admin Organizations' do

      it 'should retun an empty array' do
        expect(identity.admin_organizations).to eq([])
      end
    end

    context 'Identity is a SuperUser for an Organiztion' do

      before { create :super_user,  identity: identity,
                                    organization: organization }

      it 'should return the Organization for which the Identity is a SuperUser' do
        expect(identity.admin_organizations).to eq([organization])
      end
    end

    context 'Identity is a ServiceProvider for an Organiztion' do

      let!(:service) { create :service }

      before { create :service_provider,  identity: identity,
                                          organization: organization,
                                          service: service }

      it 'should return the Organization for which the Identity is a ServiceProvider' do
        expect(identity.admin_organizations).to eq([organization])
      end
    end

    context 'Identity is a ServiceProvider and a SuperUser for an Organiztion' do

      let!(:service) { create :service }

      before do
        create :service_provider, identity: identity,
                                  organization: organization,
                                  service: service
        create :super_user, identity: identity,
                            organization: organization
      end

      it 'should return the Organization for which the Identity is both SuperUser and ServiceProvider' do
        expect(identity.admin_organizations).to eq([organization])
      end
    end
  end
end
