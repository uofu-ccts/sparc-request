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

require 'rails_helper'
require 'timecop'

RSpec.describe ServiceRequestsController, type: :controller do
  stub_controller
  let!(:before_filters) { find_before_filters }
  let!(:logged_in_user) { create(:identity) }

  describe '#confirmation' do

    context 'added a service to a new SSR and resubmit SR' do
      before :each do
        @org         = create(:organization)
        service     = create(:service, organization: @org, one_time_fee: true)
        service2    = create(:service, organization: @org, one_time_fee: true)
        protocol    = create(:protocol_federally_funded, primary_pi: logged_in_user, type: 'Study')
        @sr          = create(:service_request_without_validations, protocol: protocol, submitted_at: Time.now.yesterday)
        @ssr         = create(:sub_service_request_without_validations, service_request: @sr, organization: @org, status: 'submitted', submitted_at: Time.now.yesterday)
        li          = create(:line_item, service_request: @sr, sub_service_request: @ssr, service: service)

        @ssr2        = create(:sub_service_request_without_validations, service_request: @sr, organization: @org, status: 'draft', submitted_at: nil)
        li_1        = create(:line_item, service_request: @sr, sub_service_request: @ssr2, service: service2)
                      create(:service_provider, identity: logged_in_user, organization: @org)

        audit = AuditRecovery.where("auditable_id = '#{li_1.id}' AND auditable_type = 'LineItem' AND action = 'create'")
        audit.first.update_attribute(:created_at, Time.now)
        audit.first.update_attribute(:user_id, logged_in_user.id)

        audit_of_ssr = AuditRecovery.where("auditable_id = '#{@ssr2.id}' AND auditable_type = 'SubServiceRequest' AND action = 'create'")
        audit_of_ssr.first.update_attribute(:created_at, Time.now)
        audit_of_ssr.first.update_attribute(:user_id, logged_in_user.id)
      end

      it 'should send request amendment email to service provider' do
        session[:identity_id]        = logged_in_user.id

        allow(Notifier).to receive(:notify_service_provider) do
          mailer = double('mail')
          expect(mailer).to receive(:deliver_now)
          mailer
        end
        xhr :get, :confirmation, {
          id: @sr.id
        }

        expect(assigns(:service_request).id).to eq(@sr.id)
        expect(assigns(:protocol).primary_principal_investigator.id).to eq(logged_in_user.id)
        expect(assigns(:sub_service_requests)[:active].count).to eq 2
        expect(assigns(:sub_service_request)).to be_nil
        expect(Notifier).to have_received(:notify_service_provider)
      end

      it 'should send request amendment email to admin' do
        @org.submission_emails.create(email: 'hedwig@owlpost.com')

        session[:identity_id]        = logged_in_user.id

        allow(Notifier).to receive(:notify_admin) do
            mailer = double('mail')
            expect(mailer).to receive(:deliver)
            mailer
          end
        xhr :get, :confirmation, {
          id: @sr.id
        }
        expect(assigns(:service_request).id).to eq(@sr.id)
        expect(assigns(:protocol).primary_principal_investigator.id).to eq(logged_in_user.id)
        expect(assigns(:sub_service_requests)[:active].count).to eq 2
        expect(assigns(:sub_service_request)).to be_nil
        expect(Notifier).to have_received(:notify_admin)
      end

      it 'should send request amendment email to authorized users' do

        session[:identity_id]        = logged_in_user.id

        allow(Notifier).to receive(:notify_user) do
            mailer = double('mail')
            expect(mailer).to receive(:deliver_now)
            mailer
          end
        xhr :get, :confirmation, {
          id: @sr.id
        }
        expect(assigns(:service_request).id).to eq(@sr.id)
        expect(assigns(:protocol).primary_principal_investigator.id).to eq(logged_in_user.id)
        expect(assigns(:sub_service_requests)[:active].count).to eq 2
        expect(assigns(:sub_service_request)).to be_nil
        expect(Notifier).to have_received(:notify_user)
      end
    end








  end
end

def setup_valid_study_answers(protocol)
  question_group = StudyTypeQuestionGroup.create(active: true)
  question_1     = StudyTypeQuestion.create(friendly_id: 'certificate_of_conf', study_type_question_group_id: question_group.id)
  question_2     = StudyTypeQuestion.create(friendly_id: 'higher_level_of_privacy', study_type_question_group_id: question_group.id)
  question_3     = StudyTypeQuestion.create(friendly_id: 'access_study_info', study_type_question_group_id: question_group.id)
  question_4     = StudyTypeQuestion.create(friendly_id: 'epic_inbasket', study_type_question_group_id: question_group.id)
  question_5     = StudyTypeQuestion.create(friendly_id: 'research_active', study_type_question_group_id: question_group.id)
  question_6     = StudyTypeQuestion.create(friendly_id: 'restrict_sending', study_type_question_group_id: question_group.id)

  answer         = StudyTypeAnswer.create(protocol_id: protocol.id, study_type_question_id: question_1.id, answer: true)
end
