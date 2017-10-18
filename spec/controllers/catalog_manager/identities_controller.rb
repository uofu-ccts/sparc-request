require 'rails_helper'

RSpec.describe CatalogManager::IdentitiesController do
  before :each do
    @identity = Identity.create(
        last_name:             'Glenn',
        first_name:            'Julia',
        ldap_uid:              'jug2@musc.edu',
        email:                 'glennj@musc.edu',
        credentials:           'BS,    MRA',
        catalog_overlord:      true,
        password:              'p4ssword',
        password_confirmation: 'p4ssword',
        approved:              true
    )

    @institution = create(:institution,
                         name:         'Medical University of South Carolina',
                         order:        1,
                         abbreviation: 'MUSC',
                         is_available: 1)
    @provider = create(:provider,
                      name:                 'South Carolina Clinical and Translational Institute (SCTR)',
                      order:                1,
                      css_class:            'blue-provider',
                      parent_id:            @institution.id,
                      abbreviation:         'SCTR1',
                      process_ssrs:         0,
                      is_available:         1)


    allow(controller).to receive(:authenticate_identity!).
      and_return(true)
    allow(controller).to receive(:current_identity).
      and_return(@identity)

  end

  describe 'associate_with_org_unit' do

    before :each do
      (1..2).each do
        post :associate_with_org_unit,
          params: { org_unit: @provider.id, identity: @identity.ldap_uid, rel_type: 'service_provider_organizational_unit' },
          xhr: true
      end
    end
    it 'should not create duplicate service provider' do
      oe = Organization.find @provider.id
      expect(oe.service_providers.length).to eq(1)
    end
  end



end
