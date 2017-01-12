require 'rails_helper'

RSpec.describe Notifier do

  let_there_be_lane
  let_there_be_j
  fake_login_for_each_test
  build_service_request_with_study

  let(:service3)           { create(:service,
                                    organization_id: program.id,
                                    name: 'ABCD',
                                    one_time_fee: true) }
  let(:identity)          { Identity.first }
  let(:organization)      { Organization.first }
  let(:non_service_provider_org)  { create(:organization, name: 'BLAH', process_ssrs: 0, is_available: 1) }
  let(:service_provider)  { create(:service_provider,
                                    identity: identity,
                                    organization: organization,
                                    service: service3) }

  before { add_visits }

  context 'new_identity_waiting_for_approval' do
    let(:mail)                    { Notifier.new_identity_waiting_for_approval(identity) }


    it 'should include approve_account_identity_url' do
      default_url_options = Rails.configuration.action_mailer.default_url_options
      puts default_url_options
      link = "#{default_url_options[:host]}:#{default_url_options[:port]}/identities/#{identity.id}/approve_account"
      puts link
      expect(mail).to have_xpath("//a[contains(@href,'#{link}')]")
    end

  end

end
