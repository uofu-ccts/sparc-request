require "rails_helper"

RSpec.describe Dashboard::DocumentsController do
  describe "GET #edit" do

    let(:logged_in_user) { create(:identity) }
    let(:other_user) { create(:identity) }

    before :each do
      log_in_dashboard_identity(obj: logged_in_user)
    end

    context 'user is authorized to edit protocol' do
      before :each do
        @protocol       = create(:protocol_without_validations, primary_pi: logged_in_user)
        organization    = create(:organization)
        service_request = create(:service_request_without_validations, protocol: @protocol)
        @ssr            = create(:sub_service_request_without_validations, service_request: service_request, organization: organization, status: 'draft')
                          create(:super_user, identity: logged_in_user, organization: organization)
        @document       = create(:document, protocol: @protocol)
        
        xhr :get, :edit, id: @document.id, format: :js
      end

      it 'should assign @document' do
        expect(assigns(:document)).to eq(@document)
      end

      it 'should assign @protocol' do
        expect(assigns(:protocol)).to eq(@protocol)
      end

      it 'should assign @admin' do
        expect(assigns(:admin)).to eq(true)
      end

      it 'should assign @authorization' do
        expect(assigns(:authorization)).to be
      end

      it 'should assign @action' do
        expect(assigns(:action)).to eq('edit')
      end

      it 'should assign @header_text' do
        expect(assigns(:header_text)).to eq('Edit Document')
      end

      it { is_expected.to respond_with :ok }
      it { is_expected.to render_template "dashboard/documents/edit" }
    end

    context 'user is not authorized to edit protocol' do
      before :each do
        protocol  = create(:protocol_without_validations, primary_pi: other_user)
        document  = create(:document, protocol: protocol)
        
        xhr :get, :edit, id: document.id, format: :js
      end

      it { is_expected.to respond_with :ok }
      it { is_expected.to render_template "dashboard/shared/_authorization_error" }
    end

    context 'user has admin access to document' do
      before :each do
        protocol        = create(:protocol_without_validations, primary_pi: other_user)
        organization    = create(:organization)
        service_request = create(:service_request_without_validations, protocol: protocol)
        ssr             = create(:sub_service_request_without_validations, service_request: service_request, organization: organization, status: 'draft')
                          create(:super_user, identity: logged_in_user, organization: organization)
        document        = create(:document, protocol: protocol)

        document.sub_service_requests = [ssr]

        xhr :get, :edit, id: document.id, format: :js
      end

      it { is_expected.to respond_with :ok }
      it { is_expected.to render_template "dashboard/documents/edit" }
    end

    context 'user does not have admin access to document' do
      before :each do
        protocol  = create(:protocol_without_validations, primary_pi: other_user)
        document  = create(:document, protocol: protocol)

        xhr :get, :edit, id: document.id, format: :js
      end

      it { is_expected.to respond_with :ok }
      it { is_expected.to render_template "dashboard/shared/_authorization_error" }
    end
  end
end
