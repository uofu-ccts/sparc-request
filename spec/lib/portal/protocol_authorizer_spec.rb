require 'rails_helper'

RSpec.describe Portal::ProtocolAuthorizer do

  describe '.can_edit?' do

    context 'one or both attributes are not present' do

      context 'Identity not present' do

        let(:protocol)            { create :protocol_without_validations }
        let(:protocol_authorizer) { Portal::ProtocolAuthorizer.new(protocol, nil) }

        it 'should return false' do
          expect { protocol_authorizer.can_edit? }.to raise_error('ProtocolAuthorizer#initialize: Missing arguments')
        end
      end

      context 'Protocol not present' do

        let(:identity)            { create :identity }
        let(:protocol_authorizer) { Portal::ProtocolAuthorizer.new(nil, identity) }

        it 'should return false' do
          expect { protocol_authorizer.can_edit? }.to raise_error('ProtocolAuthorizer#initialize: Missing arguments')
        end
      end

      context 'Protocol and Identity not present' do

        let(:protocol_authorizer) { Portal::ProtocolAuthorizer.new(nil, nil) }

        it 'should return false' do
          expect { protocol_authorizer.can_edit? }.to raise_error('ProtocolAuthorizer#initialize: Missing arguments')
        end
      end
    end

    context 'Identity is not authorized to edit Protocol' do

      let(:identity)            { create :identity }
      let(:protocol)            { create :protocol_without_validations }
      let(:protocol_authorizer) { Portal::ProtocolAuthorizer.new protocol, identity }

      context 'Identity does not have ProjectRole edit rights' do

        before { create :project_role, identity: identity, protocol: protocol }

        it 'should return false' do
          expect(protocol_authorizer.can_edit?).to_not be
        end
      end

      context 'Identity is not a super user on any organization' do

        before { create :project_role_approve, identity: identity, protocol: protocol }

      end

      context 'Identity is not a service provider on any Organization' do

      end
    end

    context 'Identity is authorized to edit Protocol' do

      let(:identity)            { create :identity }
      let(:protocol)            { create :protocol_without_validations }
      let(:protocol_authorizer) { Portal::ProtocolAuthorizer.new protocol, identity }

      before do
        organization        = create :organization
        service_request     = create :service_request_without_validations,
                                      protocol: protocol
        sub_service_request = create :sub_service_request,
                                      organization: organization,
                                      service_request: service_request

        create :project_role_approve, identity: identity, protocol: protocol
      end

      it 'should return true' do
        expect(protocol_authorizer.can_edit?).to be
      end
    end
  end
end

  # before :each do
  #   @identity = Identity.new
  #   @identity.approved = true
  #   @identity.save(validate: false)

  #   @protocol = Protocol.new
  #   @protocol.save(validate: false)
  # end

  # it 'should not authorize view and edit if both protocol and identity are nil' do
  #   pa = ProtocolAuthorizer.new(nil, nil)
  #   expect(pa.can_view?).to eq (false)
  #   expect(pa.can_edit?).to eq (false)
  # end

  # it 'should not authorize view and edit if protocol is nil' do
  #   pa = ProtocolAuthorizer.new(nil, @identity)
  #   expect(pa.can_view?).to eq (false)
  #   expect(pa.can_edit?).to eq (false)
  # end

  # it 'should not authorize view and edit if identity and project roles are nil' do
  #   pa = ProtocolAuthorizer.new(@protocol, nil)
  #   expect(pa.can_view?).to eq (false)
  #   expect(pa.can_edit?).to eq (false)
  # end

  # describe 'checks project roles and' do
  #   before :each do
  #     @project_role = ProjectRole.new
  #     @project_role.identity_id = @identity.id
  #     @project_role.protocol_id = @protocol.id
  #   end

  #   it 'should not authorize view and edit if identity is nil and projects roles size is one' do
  #     @project_role.save(validate: false)

  #     pa = ProtocolAuthorizer.new(@protocol, nil)
  #     expect(pa.can_view?).to eq (false)
  #     expect(pa.can_edit?).to eq (false)
  #   end

  #   it 'should authorize view and edit if identity has "approve" rights' do
  #     @project_role.project_rights = 'approve'
  #     @project_role.save(validate: false)

  #     pa = ProtocolAuthorizer.new(@protocol, @identity)
  #     expect(pa.can_view?).to eq (true)
  #     expect(pa.can_edit?).to eq (true)
  #   end

  #   it 'should authorize view and edit if identity has "request" rights' do
  #     @project_role.project_rights = 'request'
  #     @project_role.save(validate: false)

  #     pa = ProtocolAuthorizer.new(@protocol, @identity)
  #     expect(pa.can_view?).to eq (true)
  #     expect(pa.can_edit?).to eq (true)
  #   end

  #   it 'should authorize view only if identity has "view" rights' do
  #     @project_role.project_rights = 'view'
  #     @project_role.save(validate: false)

  #     pa = ProtocolAuthorizer.new(@protocol, @identity)
  #     expect(pa.can_view?).to eq (true)
  #     expect(pa.can_edit?).to eq (false)
  #   end

  #   it 'should not authorize view and edit if identity has "none" rights' do
  #     @project_role.project_rights = 'none'
  #     @project_role.save(validate: false)

  #     pa = ProtocolAuthorizer.new(@protocol, @identity)
  #     expect(pa.can_view?).to eq (false)
  #     expect(pa.can_edit?).to eq (false)
  #   end

  #   it 'should not authorize view and edit if identity has empty "" rights' do
  #     @project_role.project_rights = ''
  #     @project_role.save(validate: false)

  #     pa = ProtocolAuthorizer.new(@protocol, @identity)
  #     expect(pa.can_view?).to eq (false)
  #     expect(pa.can_edit?).to eq (false)
  #   end

  #   it 'should NOT authorize view and edit if another identity has "approve" rights' do
  #     @associated_user = Identity.new
  #     @associated_user.approved = true
  #     @associated_user.save(validate: false)

  #     @associated_user_project_role = ProjectRole.new
  #     @associated_user_project_role.identity_id = @associated_user.id
  #     @associated_user_project_role.protocol_id = @protocol.id
  #     @associated_user_project_role.project_rights = 'approve'
  #     @associated_user_project_role.save(validate: false)

  #     pa = ProtocolAuthorizer.new(@protocol, @identity)
  #     expect(pa.can_view?).to eq (false)
  #     expect(pa.can_edit?).to eq (false)
  #   end

  #   it 'should NOT authorize view and edit if another identity has "view" rights' do
  #     @associated_user = Identity.new
  #     @associated_user.approved = true
  #     @associated_user.save(validate: false)

  #     @associated_user_project_role = ProjectRole.new
  #     @associated_user_project_role.identity_id = @associated_user.id
  #     @associated_user_project_role.protocol_id = @protocol.id
  #     @associated_user_project_role.project_rights = 'view'
  #     @associated_user_project_role.save(validate: false)

  #     pa = ProtocolAuthorizer.new(@protocol, @identity)
  #     expect(pa.can_view?).to eq (false)
  #     expect(pa.can_edit?).to eq (false)
  #   end
  # end

  # describe 'checks service providers, clinical providers, and super users for a ' do
  #   before :each do
  #     # create service request and associate it to a protocol via an organization (i.e., core)
  #     @institution = Institution.new
  #     @institution.type = "Institution"
  #     @institution.abbreviation = "TECHU"
  #     @institution.save(validate: false)

  #     @provider = Provider.new
  #     @provider.type = "Provider"
  #     @provider.abbreviation = "ICTS"
  #     @provider.parent_id = @institution.id
  #     @provider.save(validate: false)

  #     @program = Program.new
  #     @program.type = "Program"
  #     @program.name = "BMI"
  #     @program.parent_id = @provider.id
  #     @program.save(validate: false)

  #     @core = Core.new
  #     @core.type = "Core"
  #     @core.name = "REDCap"
  #     @core.parent_id = @program.id
  #     @core.save(validate: false)

  #     @service_request = ServiceRequest.new
  #     @service_request.protocol_id = @protocol.id
  #     @service_request.save(validate: false)
  #   end

  #   describe 'sub service request connected to a core and users within' do
  #     before :each do
  #       @sub_service_request = SubServiceRequest.new
  #       @sub_service_request.organization_id = @core.id
  #       @sub_service_request.service_request_id = @service_request.id
  #       @sub_service_request.save(validate: false)
  #     end

  #     describe 'cores' do
  #       it 'should authorize view and edit if identity is a service provider for a sub service request that is servicing the protocol' do
  #         @service_provider = ServiceProvider.new
  #         @service_provider.identity_id = @identity.id
  #         @service_provider.organization_id = @core.id
  #         @service_provider.save(validate: false)

  #         pa = ProtocolAuthorizer.new(@protocol, @identity)
  #         expect(pa.can_view?).to eq (true)
  #         expect(pa.can_edit?).to eq (true)
  #       end

  #       it 'should NOT authorize view and edit if identity is a clinical provider for a sub service request that is servicing the protocol' do
  #         @clinical_provider = ClinicalProvider.new
  #         @clinical_provider.identity_id = @identity.id
  #         @clinical_provider.organization_id = @core.id
  #         @clinical_provider.save(validate: false)

  #         pa = ProtocolAuthorizer.new(@protocol, @identity)
  #         expect(pa.can_view?).to eq (false)
  #         expect(pa.can_edit?).to eq (false)
  #       end

  #       it 'should authorize view and edit if identity is a super user for a sub service request that is servicing the protocol' do
  #         @super_user = SuperUser.new
  #         @super_user.identity_id = @identity.id
  #         @super_user.organization_id = @core.id
  #         @super_user.save(validate: false)

  #         pa = ProtocolAuthorizer.new(@protocol, @identity)
  #         expect(pa.can_view?).to eq (true)
  #         expect(pa.can_edit?).to eq (true)
  #       end
  #     end

  #     describe 'unrelated cores' do
  #       before :each do
  #         @unrelated_core = Core.new
  #         @unrelated_core.type = "Core"
  #         @unrelated_core.name = "REDCap 2"
  #         @unrelated_core.parent_id = @program.id
  #         @unrelated_core.save(validate: false)
  #       end

  #       it 'should NOT authorize view and edit if identity is a service provider for an unrelated core' do
  #         @service_provider = ServiceProvider.new
  #         @service_provider.identity_id = @identity.id
  #         @service_provider.organization_id = @unrelated_core.id
  #         @service_provider.save(validate: false)

  #         pa = ProtocolAuthorizer.new(@protocol, @identity)
  #         expect(pa.can_view?).to eq (false)
  #         expect(pa.can_edit?).to eq (false)
  #       end

  #       it 'should NOT authorize view and edit if identity is a clinical provider for an unrelated core' do
  #         @clinical_provider = ClinicalProvider.new
  #         @clinical_provider.identity_id = @identity.id
  #         @clinical_provider.organization_id = @unrelated_core.id
  #         @clinical_provider.save(validate: false)

  #         pa = ProtocolAuthorizer.new(@protocol, @identity)
  #         expect(pa.can_view?).to eq (false)
  #         expect(pa.can_edit?).to eq (false)
  #       end

  #       it 'should NOT authorize view and edit if identity is a super user for an unrelated core' do
  #         @super_user = SuperUser.new
  #         @super_user.identity_id = @identity.id
  #         @super_user.organization_id = @unrelated_core.id
  #         @super_user.save(validate: false)

  #         pa = ProtocolAuthorizer.new(@protocol, @identity)
  #         expect(pa.can_view?).to eq (false)
  #         expect(pa.can_edit?).to eq (false)
  #       end

  #     end

  #     describe 'programs' do
  #       it 'should authorize view and edit if identity is a service provider for a sub service request that is servicing the protocol' do
  #         @service_provider = ServiceProvider.new
  #         @service_provider.identity_id = @identity.id
  #         @service_provider.organization_id = @program.id
  #         @service_provider.save(validate: false)

  #         pa = ProtocolAuthorizer.new(@protocol, @identity)
  #         expect(pa.can_view?).to eq (true)
  #         expect(pa.can_edit?).to eq (true)
  #       end

  #       it 'should NOT authorize view and edit if identity is a clinical provider for a sub service request that is servicing the protocol' do
  #         @clinical_provider = ClinicalProvider.new
  #         @clinical_provider.identity_id = @identity.id
  #         @clinical_provider.organization_id = @program.id
  #         @clinical_provider.save(validate: false)

  #         pa = ProtocolAuthorizer.new(@protocol, @identity)
  #         expect(pa.can_view?).to eq (false)
  #         expect(pa.can_edit?).to eq (false)
  #       end

  #       it 'should authorize view and edit if identity is a super user for a sub service request that is servicing the protocol' do
  #         @super_user = SuperUser.new
  #         @super_user.identity_id = @identity.id
  #         @super_user.organization_id = @program.id
  #         @super_user.save(validate: false)

  #         pa = ProtocolAuthorizer.new(@protocol, @identity)
  #         expect(pa.can_view?).to eq (true)
  #         expect(pa.can_edit?).to eq (true)
  #       end
  #     end

  #     describe 'unrelated programs' do
  #       before :each do
  #         @unrelated_program = Program.new
  #         @unrelated_program.type = "Program"
  #         @unrelated_program.name = "BMI 2"
  #         @unrelated_program.parent_id = @provider.id
  #         @unrelated_program.save(validate: false)
  #       end

  #       it 'should NOT authorize view and edit if identity is a service provider for an unrelated program' do
  #         @service_provider = ServiceProvider.new
  #         @service_provider.identity_id = @identity.id
  #         @service_provider.organization_id = @unrelated_program.id
  #         @service_provider.save(validate: false)

  #         pa = ProtocolAuthorizer.new(@protocol, @identity)
  #         expect(pa.can_view?).to eq (false)
  #         expect(pa.can_edit?).to eq (false)
  #       end

  #       it 'should NOT authorize view and edit if identity is a clinical provider for an unrelated program' do
  #         @clinical_provider = ClinicalProvider.new
  #         @clinical_provider.identity_id = @identity.id
  #         @clinical_provider.organization_id = @unrelated_program.id
  #         @clinical_provider.save(validate: false)

  #         pa = ProtocolAuthorizer.new(@protocol, @identity)
  #         expect(pa.can_view?).to eq (false)
  #         expect(pa.can_edit?).to eq (false)
  #       end

  #       it 'should NOT authorize view and edit if identity is a super user for  an unrelated program' do
  #         @super_user = SuperUser.new
  #         @super_user.identity_id = @identity.id
  #         @super_user.organization_id = @unrelated_program.id
  #         @super_user.save(validate: false)

  #         pa = ProtocolAuthorizer.new(@protocol, @identity)
  #         expect(pa.can_view?).to eq (false)
  #         expect(pa.can_edit?).to eq (false)
  #       end
  #     end

  #     describe 'providers' do
  #       it 'should authorize view and edit if identity is a service provider for a sub service request that is servicing the protocol' do
  #         @service_provider = ServiceProvider.new
  #         @service_provider.identity_id = @identity.id
  #         @service_provider.organization_id = @provider.id
  #         @service_provider.save(validate: false)

  #         pa = ProtocolAuthorizer.new(@protocol, @identity)
  #         expect(pa.can_view?).to eq (true)
  #         expect(pa.can_edit?).to eq (true)
  #       end

  #       it 'should NOT authorize view and edit even if identity is a clinical provider for a provider' do
  #         @clinical_provider = ClinicalProvider.new
  #         @clinical_provider.identity_id = @identity.id
  #         @clinical_provider.organization_id = @provider.id
  #         @clinical_provider.save(validate: false)

  #         pa = ProtocolAuthorizer.new(@protocol, @identity)
  #         expect(pa.can_view?).to eq (false)
  #         expect(pa.can_edit?).to eq (false)
  #       end

  #       it 'should authorize view and edit if identity is a super user for a sub service request that is servicing the protocol' do
  #         @super_user = SuperUser.new
  #         @super_user.identity_id = @identity.id
  #         @super_user.organization_id = @provider.id
  #         @super_user.save(validate: false)

  #         pa = ProtocolAuthorizer.new(@protocol, @identity)
  #         expect(pa.can_view?).to eq (true)
  #         expect(pa.can_edit?).to eq (true)
  #       end
  #     end

  #     describe 'unrelated providers' do
  #       before :each do
  #         @unrelated_provider = Provider.new
  #         @unrelated_provider.type = "Provider"
  #         @unrelated_provider.abbreviation = "ICTS 2"
  #         @unrelated_provider.parent_id = @institution.id
  #         @unrelated_provider.save(validate: false)
  #       end

  #       it 'should NOT authorize view and edit if identity is a service provider for an unrelated provider' do
  #         @service_provider = ServiceProvider.new
  #         @service_provider.identity_id = @identity.id
  #         @service_provider.organization_id = @unrelated_provider.id
  #         @service_provider.save(validate: false)

  #         pa = ProtocolAuthorizer.new(@protocol, @identity)
  #         expect(pa.can_view?).to eq (false)
  #         expect(pa.can_edit?).to eq (false)
  #       end

  #       it 'should NOT authorize view and edit if identity is a super user for an unrelated provider' do
  #         @super_user = SuperUser.new
  #         @super_user.identity_id = @identity.id
  #         @super_user.organization_id = @unrelated_provider.id
  #         @super_user.save(validate: false)

  #         pa = ProtocolAuthorizer.new(@protocol, @identity)
  #         expect(pa.can_view?).to eq (false)
  #         expect(pa.can_edit?).to eq (false)
  #       end
  #     end

  #     describe 'institutions' do
  #       it 'should authorize view and edit if identity is a super user for a sub service request that is servicing the protocol' do
  #         @super_user = SuperUser.new
  #         @super_user.identity_id = @identity.id
  #         @super_user.organization_id = @institution.id
  #         @super_user.save(validate: false)

  #         pa = ProtocolAuthorizer.new(@protocol, @identity)
  #         expect(pa.can_view?).to eq (true)
  #         expect(pa.can_edit?).to eq (true)
  #       end
  #     end

  #     describe 'unrelated institutions' do
  #       before :each do
  #         @unrelated_institution = Institution.new
  #         @unrelated_institution.type = "Institution"
  #         @unrelated_institution.abbreviation = "TECHU 2"
  #         @unrelated_institution.save(validate: false)
  #       end

  #       it 'should NOT authorize view and edit if identity is a super user for an unrelated institution' do
  #         @super_user = SuperUser.new
  #         @super_user.identity_id = @identity.id
  #         @super_user.organization_id = @unrelated_institution.id
  #         @super_user.save(validate: false)

  #         pa = ProtocolAuthorizer.new(@protocol, @identity)
  #         expect(pa.can_view?).to eq (false)
  #         expect(pa.can_edit?).to eq (false)
  #       end
  #     end
  #   end

  #   describe 'sub service request connected to a program and users within' do
  #     before :each do
  #       @sub_service_request = SubServiceRequest.new
  #       @sub_service_request.organization_id = @program.id
  #       @sub_service_request.service_request_id = @service_request.id
  #       @sub_service_request.save(validate: false)
  #     end

  #     describe 'cores' do
  #       it 'should NOT authorize view and edit' do
  #         @service_provider = ServiceProvider.new
  #         @service_provider.identity_id = @identity.id
  #         @service_provider.organization_id = @core.id
  #         @service_provider.save(validate: false)

  #         pa = ProtocolAuthorizer.new(@protocol, @identity)
  #         expect(pa.can_view?).to eq (false)
  #         expect(pa.can_edit?).to eq (false)
  #       end

  #       it 'should NOT authorize view and edit' do
  #         @clinical_provider = ClinicalProvider.new
  #         @clinical_provider.identity_id = @identity.id
  #         @clinical_provider.organization_id = @core.id
  #         @clinical_provider.save(validate: false)

  #         pa = ProtocolAuthorizer.new(@protocol, @identity)
  #         expect(pa.can_view?).to eq (false)
  #         expect(pa.can_edit?).to eq (false)
  #       end

  #       it 'should NOT authorize view and edit' do
  #         @super_user = SuperUser.new
  #         @super_user.identity_id = @identity.id
  #         @super_user.organization_id = @core.id
  #         @super_user.save(validate: false)

  #         pa = ProtocolAuthorizer.new(@protocol, @identity)
  #         expect(pa.can_view?).to eq (false)
  #         expect(pa.can_edit?).to eq (false)
  #       end
  #     end

  #     describe 'programs' do
  #       it 'should authorize view and edit if identity is a service provider for a sub service request that is servicing the protocol' do
  #         @service_provider = ServiceProvider.new
  #         @service_provider.identity_id = @identity.id
  #         @service_provider.organization_id = @program.id
  #         @service_provider.save(validate: false)

  #         pa = ProtocolAuthorizer.new(@protocol, @identity)
  #         expect(pa.can_view?).to eq (true)
  #         expect(pa.can_edit?).to eq (true)
  #       end

  #       it 'should NOT authorize view and edit if identity is a clinical provider for a sub service request that is servicing the protocol' do
  #         @clinical_provider = ClinicalProvider.new
  #         @clinical_provider.identity_id = @identity.id
  #         @clinical_provider.organization_id = @program.id
  #         @clinical_provider.save(validate: false)

  #         pa = ProtocolAuthorizer.new(@protocol, @identity)
  #         expect(pa.can_view?).to eq (false)
  #         expect(pa.can_edit?).to eq (false)
  #       end

  #       it 'should authorize view and edit if identity is a super user for a sub service request that is servicing the protocol' do
  #         @super_user = SuperUser.new
  #         @super_user.identity_id = @identity.id
  #         @super_user.organization_id = @program.id
  #         @super_user.save(validate: false)

  #         pa = ProtocolAuthorizer.new(@protocol, @identity)
  #         expect(pa.can_view?).to eq (true)
  #         expect(pa.can_edit?).to eq (true)
  #       end
  #     end

  #     describe 'unrelated programs' do
  #       before :each do
  #         @unrelated_program = Program.new
  #         @unrelated_program.type = "Program"
  #         @unrelated_program.name = "BMI 2"
  #         @unrelated_program.parent_id = @provider.id
  #         @unrelated_program.save(validate: false)
  #       end

  #       it 'should NOT authorize view and edit if identity is a service provider for an unrelated program' do
  #         @service_provider = ServiceProvider.new
  #         @service_provider.identity_id = @identity.id
  #         @service_provider.organization_id = @unrelated_program.id
  #         @service_provider.save(validate: false)

  #         pa = ProtocolAuthorizer.new(@protocol, @identity)
  #         expect(pa.can_view?).to eq (false)
  #         expect(pa.can_edit?).to eq (false)
  #       end

  #       it 'should NOT authorize view and edit if identity is a clinical provider for an unrelated program' do
  #         @clinical_provider = ClinicalProvider.new
  #         @clinical_provider.identity_id = @identity.id
  #         @clinical_provider.organization_id = @unrelated_program.id
  #         @clinical_provider.save(validate: false)

  #         pa = ProtocolAuthorizer.new(@protocol, @identity)
  #         expect(pa.can_view?).to eq (false)
  #         expect(pa.can_edit?).to eq (false)
  #       end

  #       it 'should NOT authorize view and edit if identity is a super user for  an unrelated program' do
  #         @super_user = SuperUser.new
  #         @super_user.identity_id = @identity.id
  #         @super_user.organization_id = @unrelated_program.id
  #         @super_user.save(validate: false)

  #         pa = ProtocolAuthorizer.new(@protocol, @identity)
  #         expect(pa.can_view?).to eq (false)
  #         expect(pa.can_edit?).to eq (false)
  #       end
  #     end

  #     describe 'providers' do
  #       it 'should authorize view and edit if identity is a service provider for a sub service request that is servicing the protocol' do
  #         @service_provider = ServiceProvider.new
  #         @service_provider.identity_id = @identity.id
  #         @service_provider.organization_id = @provider.id
  #         @service_provider.save(validate: false)

  #         pa = ProtocolAuthorizer.new(@protocol, @identity)
  #         expect(pa.can_view?).to eq (true)
  #         expect(pa.can_edit?).to eq (true)
  #       end

  #       it 'should NOT authorize view and edit even if identity is a clinical provider for a provider' do
  #         @clinical_provider = ClinicalProvider.new
  #         @clinical_provider.identity_id = @identity.id
  #         @clinical_provider.organization_id = @provider.id
  #         @clinical_provider.save(validate: false)

  #         pa = ProtocolAuthorizer.new(@protocol, @identity)
  #         expect(pa.can_view?).to eq (false)
  #         expect(pa.can_edit?).to eq (false)
  #       end

  #       it 'should authorize view and edit if identity is a super user for a sub service request that is servicing the protocol' do
  #         @super_user = SuperUser.new
  #         @super_user.identity_id = @identity.id
  #         @super_user.organization_id = @provider.id
  #         @super_user.save(validate: false)

  #         pa = ProtocolAuthorizer.new(@protocol, @identity)
  #         expect(pa.can_view?).to eq (true)
  #         expect(pa.can_edit?).to eq (true)
  #       end
  #     end

  #     describe 'unrelated providers' do
  #       before :each do
  #         @unrelated_provider = Provider.new
  #         @unrelated_provider.type = "Provider"
  #         @unrelated_provider.abbreviation = "ICTS 2"
  #         @unrelated_provider.parent_id = @institution.id
  #         @unrelated_provider.save(validate: false)
  #       end

  #       it 'should NOT authorize view and edit if identity is a service provider for an unrelated provider' do
  #         @service_provider = ServiceProvider.new
  #         @service_provider.identity_id = @identity.id
  #         @service_provider.organization_id = @unrelated_provider.id
  #         @service_provider.save(validate: false)

  #         pa = ProtocolAuthorizer.new(@protocol, @identity)
  #         expect(pa.can_view?).to eq (false)
  #         expect(pa.can_edit?).to eq (false)
  #       end

  #       it 'should NOT authorize view and edit if identity is a super user for an unrelated provider' do
  #         @super_user = SuperUser.new
  #         @super_user.identity_id = @identity.id
  #         @super_user.organization_id = @unrelated_provider.id
  #         @super_user.save(validate: false)

  #         pa = ProtocolAuthorizer.new(@protocol, @identity)
  #         expect(pa.can_view?).to eq (false)
  #         expect(pa.can_edit?).to eq (false)
  #       end
  #     end

  #     describe 'institutions' do
  #       it 'should authorize view and edit if identity is a super user for a sub service request that is servicing the protocol' do
  #         @super_user = SuperUser.new
  #         @super_user.identity_id = @identity.id
  #         @super_user.organization_id = @institution.id
  #         @super_user.save(validate: false)

  #         pa = ProtocolAuthorizer.new(@protocol, @identity)
  #         expect(pa.can_view?).to eq (true)
  #         expect(pa.can_edit?).to eq (true)
  #       end
  #     end

  #     describe 'unrelated institutions' do
  #       before :each do
  #         @unrelated_institution = Institution.new
  #         @unrelated_institution.type = "Institution"
  #         @unrelated_institution.abbreviation = "TECHU 2"
  #         @unrelated_institution.save(validate: false)
  #       end

  #       it 'should NOT authorize view and edit if identity is a super user for an unrelated institution' do
  #         @super_user = SuperUser.new
  #         @super_user.identity_id = @identity.id
  #         @super_user.organization_id = @unrelated_institution.id
  #         @super_user.save(validate: false)

  #         pa = ProtocolAuthorizer.new(@protocol, @identity)
  #         expect(pa.can_view?).to eq (false)
  #         expect(pa.can_edit?).to eq (false)
  #       end
  #     end
  #   end

  # end

# end
