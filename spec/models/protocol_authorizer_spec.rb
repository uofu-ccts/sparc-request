# Copyright © 2011 MUSC Foundation for Research Development
# All rights reserved.

# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following
# disclaimer in the documentation and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products
# derived from this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
# BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
# SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
# TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require 'date'
require 'rails_helper'

RSpec.describe 'ProtocolAuthorizer', type: :model do
  # data that can be setup and references memoized
  # these can persist between tests
  def protocol
    @protocol ||= create(:protocol_without_validations)
  end

  def identity
    @identity ||= create(:identity, approved: true)
  end

  def institution
    @institution ||= create(:institution_without_validations, abbreviation: 'TECHU')
  end

  def provider
    @provider ||= create(:provider_without_validations, abbreviation: 'ICTS', parent_id: institution.id)
  end

  def program
    @program ||= create(:program_without_validations, abbreviation: 'BMI', parent_id: provider.id)
  end

  def core
    @core ||= create(:core_without_validations, abbreviation: 'REDCap', parent_id: program.id)
  end

  def service_request
    @service_request ||= create(:service_request_without_validations, protocol: protocol)
  end

  it 'should not authorize view and edit if both protocol and identity are nil' do
    pa = ProtocolAuthorizer.new(nil, nil)
    expect(pa.can_view?).to eq(false)
    expect(pa.can_edit?).to eq(false)
  end

  it 'should not authorize view and edit if protocol is nil' do
    pa = ProtocolAuthorizer.new(nil, identity)

    expect(pa.can_view?).to eq(false)
    expect(pa.can_edit?).to eq(false)
  end

  it 'should not authorize view and edit if identity and project roles are nil' do
    pa = ProtocolAuthorizer.new(protocol, nil)

    expect(pa.can_view?).to eq(false)
    expect(pa.can_edit?).to eq(false)
  end

  describe 'checks project roles and' do
    it 'should authorize view and edit if identity has "approve" rights' do
      ProjectRole.create(identity_id: identity.id, protocol_id: protocol.id,
        project_rights: 'approve', role: 'mentor')
      pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)

      expect(pa.can_view?).to eq(true)
      expect(pa.can_edit?).to eq(true)
    end

    it 'should authorize view and edit if identity has "request" rights' do
      ProjectRole.create(identity_id: identity.id, protocol_id: protocol.id,
        project_rights: 'request', role: 'mentor')
      pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)

      expect(pa.can_view?).to eq(true)
      expect(pa.can_edit?).to eq(true)
    end

    it 'should authorize view only if identity has "view" rights' do
      ProjectRole.create(identity_id: identity.id, protocol_id: protocol.id,
        project_rights: 'view', role: 'mentor')
      pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)

      expect(pa.can_view?).to eq(true)
      expect(pa.can_edit?).to eq(false)
    end

    it 'should not authorize view and edit if identity has "none" rights' do
      ProjectRole.create(identity_id: identity.id, protocol_id: protocol.id,
        project_rights: 'none', role: 'mentor')
      pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)
      
      expect(pa.can_view?).to eq(false)
      expect(pa.can_edit?).to eq(false)
    end
  end

  describe 'checks service providers, clinical providers, and super users for a ' do
    describe 'sub service request connected to a core and users within' do
      let!(:sub_service_request) { create(:sub_service_request, organization_id: core.id, service_request: service_request) }

      describe 'cores' do
        it 'should authorize view and edit if identity is a service provider for a sub service request that is servicing the protocol' do
          ServiceProvider.create(identity_id: identity.id, organization_id: core.id)
          pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)

          expect(pa.can_view?).to eq(true)
          expect(pa.can_edit?).to eq(true)
        end

        it 'should NOT authorize view and edit if identity is a clinical provider for a sub service request that is servicing the protocol' do
          ClinicalProvider.create(identity_id: identity.id, organization_id: core.id)
          pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)

          expect(pa.can_view?).to eq(false)
          expect(pa.can_edit?).to eq(false)
        end

        it 'should authorize view and edit if identity is a super user for a sub service request that is servicing the protocol' do
          SuperUser.create(identity_id: identity.id, organization_id: core.id)
          pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)

          expect(pa.can_view?).to eq(true)
          expect(pa.can_edit?).to eq(true)
        end
      end

      describe 'unrelated cores' do
        let!(:unrelated_core) { create(:core_without_validations, name: 'REDCap 2') }

        it 'should NOT authorize view and edit if identity is a service provider for an unrelated core' do
          ServiceProvider.create(identity_id: identity.id, organization_id: unrelated_core.id)
          pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)

          expect(pa.can_view?).to eq(false)
          expect(pa.can_edit?).to eq(false)
        end

        it 'should NOT authorize view and edit if identity is a clinical provider for an unrelated core' do
          ClinicalProvider.create(identity_id: identity.id, organization_id: unrelated_core.id)
          pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)

          expect(pa.can_view?).to eq(false)
          expect(pa.can_edit?).to eq(false)
        end

        it 'should NOT authorize view and edit if identity is a super user for an unrelated core' do
          SuperUser.create(identity_id: identity.id, organization_id: unrelated_core.id)
          pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)

          expect(pa.can_view?).to eq(false)
          expect(pa.can_edit?).to eq(false)
        end
      end

      describe 'programs' do

        it 'should authorize view and edit if identity is a service provider for a sub service request that is servicing the protocol' do
          ServiceProvider.create(identity_id: identity.id, organization_id: program.id)
          pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)

          expect(pa.can_view?).to eq(true)
          expect(pa.can_edit?).to eq(true)
        end

        it 'should NOT authorize view and edit if identity is a clinical provider for a sub service request that is servicing the protocol' do
          ClinicalProvider.create(identity_id: identity.id, organization_id: program.id)
          pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)

          expect(pa.can_view?).to eq(false)
          expect(pa.can_edit?).to eq(false)
        end

        it 'should authorize view and edit if identity is a super user for a sub service request that is servicing the protocol' do
          SuperUser.create(identity_id: identity.id, organization_id: program.id)
          pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)

          expect(pa.can_view?).to eq(true)
          expect(pa.can_edit?).to eq(true)
        end
      end

      describe 'unrelated programs' do
        let!(:unrelated_program) do
          create(:program_without_validations, name: 'BMI 2',
            parent_id: provider.id)
        end

        it 'should NOT authorize view and edit if identity is a service provider for an unrelated program' do
          ServiceProvider.create(identity_id: identity.id, organization_id: unrelated_program.id)
          pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)

          expect(pa.can_view?).to eq(false)
          expect(pa.can_edit?).to eq(false)
        end

        it 'should NOT authorize view and edit if identity is a clinical provider for an unrelated program' do
          ClinicalProvider.create(identity_id: identity.id, organization_id: unrelated_program.id)
          pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)

          expect(pa.can_view?).to eq(false)
          expect(pa.can_edit?).to eq(false)
        end

        it 'should NOT authorize view and edit if identity is a super user for  an unrelated program' do
          SuperUser.create(identity_id: identity.id, organization_id: unrelated_program.id)
          pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)

          expect(pa.can_view?).to eq(false)
          expect(pa.can_edit?).to eq(false)
        end
      end

      describe 'providers' do
        it 'should authorize view and edit if identity is a service provider for a sub service request that is servicing the protocol' do
          ServiceProvider.create(identity_id: identity.id, organization_id: provider.id)
          pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)

          expect(pa.can_view?).to eq(true)
          expect(pa.can_edit?).to eq(true)
        end

        it 'should NOT authorize view and edit even if identity is a clinical provider for a provider' do
          ClinicalProvider.create(identity_id: identity.id, organization_id: provider.id)
          pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)

          expect(pa.can_view?).to eq(false)
          expect(pa.can_edit?).to eq(false)
        end

        it 'should authorize view and edit if identity is a super user for a sub service request that is servicing the protocol' do
          SuperUser.create(identity_id: identity.id, organization_id: provider.id)
          pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)

          expect(pa.can_view?).to eq(true)
          expect(pa.can_edit?).to eq(true)
        end
      end

      describe 'unrelated providers' do
        let!(:unrelated_provider) do
          create(:provider_without_validations, abbreviation: 'ICTS 2',
            parent_id: institution.id)
        end

        it 'should NOT authorize view and edit if identity is a service provider for an unrelated provider' do
          ServiceProvider.create(identity_id: identity.id, organization_id: unrelated_provider.id)
          pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)

          expect(pa.can_view?).to eq(false)
          expect(pa.can_edit?).to eq(false)
        end

        it 'should NOT authorize view and edit if identity is a super user for an unrelated provider' do
          SuperUser.create(identity_id: identity.id, organization_id: unrelated_provider.id)
          pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)

          expect(pa.can_view?).to eq(false)
          expect(pa.can_edit?).to eq(false)
        end
      end

      describe 'institutions' do
        it 'should authorize view and edit if identity is a super user for a sub service request that is servicing the protocol' do
          SuperUser.create(identity_id: identity.id, organization_id: institution.id)
          pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)

          expect(pa.can_view?).to eq(true)
          expect(pa.can_edit?).to eq(true)
        end
      end

      describe 'unrelated institutions' do
        let!(:unrelated_institution) { create(:institution_without_validations, abbreviation: 'TECHNU 2') }

        it 'should NOT authorize view and edit if identity is a super user for an unrelated institution' do
          SuperUser.create(identity_id: identity.id, organization_id: unrelated_institution.id)
          pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)

          expect(pa.can_view?).to eq(false)
          expect(pa.can_edit?).to eq(false)
        end
      end
    end

    describe 'sub service request connected to a program and users within' do
      let!(:sub_service_request) { create(:sub_service_request, organization_id: program.id, service_request: service_request) }

      describe 'cores' do
        it 'should NOT authorize view and edit' do
          ServiceProvider.create(identity_id: identity.id, organization_id: core.id)
          pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)

          expect(pa.can_view?).to eq(false)
          expect(pa.can_edit?).to eq(false)
        end

        it 'should NOT authorize view and edit' do
          ClinicalProvider.create(identity_id: identity.id, organization_id: core.id)
          pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)

          expect(pa.can_view?).to eq(false)
          expect(pa.can_edit?).to eq(false)
        end

        it 'should NOT authorize view and edit' do
          SuperUser.create(identity_id: identity.id, organization_id: core.id)
          pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)

          expect(pa.can_view?).to eq(false)
          expect(pa.can_edit?).to eq(false)
        end
      end

      describe 'programs' do
        it 'should authorize view and edit if identity is a service provider for a sub service request that is servicing the protocol' do
          ServiceProvider.create(identity_id: identity.id, organization_id: program.id)
          pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)

          expect(pa.can_view?).to eq(true)
          expect(pa.can_edit?).to eq(true)
        end

        it 'should NOT authorize view and edit if identity is a clinical provider for a sub service request that is servicing the protocol' do
          ClinicalProvider.create(identity_id: identity.id, organization_id: program.id)
          pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)

          expect(pa.can_view?).to eq(false)
          expect(pa.can_edit?).to eq(false)
        end

        it 'should authorize view and edit if identity is a super user for a sub service request that is servicing the protocol' do
          SuperUser.create(identity_id: identity.id, organization_id: program.id)
          pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)

          expect(pa.can_view?).to eq(true)
          expect(pa.can_edit?).to eq(true)
        end
      end

      describe 'unrelated programs' do
        let!(:unrelated_program) { create(:program_without_validations, name: 'BMI 2', parent_id: provider.id) }

        it 'should NOT authorize view and edit if identity is a service provider for an unrelated program' do
          ServiceProvider.create(identity_id: identity.id, organization_id: unrelated_program.id)
          pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)

          expect(pa.can_view?).to eq(false)
          expect(pa.can_edit?).to eq(false)
        end

        it 'should NOT authorize view and edit if identity is a clinical provider for an unrelated program' do
          ClinicalProvider.create(identity_id: identity.id, organization_id: unrelated_program.id)
          pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)

          expect(pa.can_view?).to eq(false)
          expect(pa.can_edit?).to eq(false)
        end

        it 'should NOT authorize view and edit if identity is a super user for  an unrelated program' do
          SuperUser.create(identity_id: identity.id, organization_id: unrelated_program.id)
          pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)

          expect(pa.can_view?).to eq(false)
          expect(pa.can_edit?).to eq(false)
        end
      end

      describe 'providers' do
        it 'should authorize view and edit if identity is a service provider for a sub service request that is servicing the protocol' do
          ServiceProvider.create(identity_id: identity.id, organization_id: provider.id)
          pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)

          expect(pa.can_view?).to eq(true)
          expect(pa.can_edit?).to eq(true)
        end

        it 'should NOT authorize view and edit even if identity is a clinical provider for a provider' do
          ClinicalProvider.create(identity_id: identity.id, organization_id: provider.id)
          pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)

          expect(pa.can_view?).to eq(false)
          expect(pa.can_edit?).to eq(false)
        end

        it 'should authorize view and edit if identity is a super user for a sub service request that is servicing the protocol' do
          SuperUser.create(identity_id: identity.id, organization_id: provider.id)
          pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)

          expect(pa.can_view?).to eq(true)
          expect(pa.can_edit?).to eq(true)
        end
      end

      describe 'unrelated providers' do
        let!(:unrelated_provider) { create(:provider_without_validations, abbreviation: 'ICTS 2', parent_id: institution.id) }

        it 'should NOT authorize view and edit if identity is a service provider for an unrelated provider' do
          ServiceProvider.create(identity_id: identity.id, organization_id: unrelated_provider.id)
          pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)

          expect(pa.can_view?).to eq(false)
          expect(pa.can_edit?).to eq(false)
        end

        it 'should NOT authorize view and edit if identity is a super user for an unrelated provider' do
          SuperUser.create(identity_id: identity.id, organization_id: unrelated_provider.id)
          pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)

          expect(pa.can_view?).to eq(false)
          expect(pa.can_edit?).to eq(false)
        end
      end

      describe 'institutions' do
        it 'should authorize view and edit if identity is a super user for a sub service request that is servicing the protocol' do
          SuperUser.create(identity_id: identity.id, organization_id: institution.id)
          pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)

          expect(pa.can_view?).to eq(true)
          expect(pa.can_edit?).to eq(true)
        end
      end

      describe 'unrelated institutions' do
        let!(:unrelated_institution) { create(:institution_without_validations, abbreviation: 'TECHU 2') }

        it 'should NOT authorize view and edit if identity is a super user for an unrelated institution' do
          SuperUser.create(identity_id: identity.id, organization_id: unrelated_institution.id)
          pa = ProtocolAuthorizer.new(protocol.reload, identity.reload)

          expect(pa.can_view?).to eq(false)
          expect(pa.can_edit?).to eq(false)
        end
      end
    end
  end
end
