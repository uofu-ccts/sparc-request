require "rails_helper"

RSpec.describe ContactMailer, type: :mailer do
  let!(:contact_form) do
    FactoryGirl.create(:contact_form, subject: 'subject', email: 'example@example.com', message: 'message')
  end

  let(:mail) do
    ContactMailer.contact_us_email(contact_form)
  end

  let(:cc) do
    if defined? CONTACT_US_EMAIL
      [CONTACT_US_EMAIL['cc']]
    else
      ['sparcrequest@gmail.com']
    end
  end

  let(:to) do
    if defined? CONTACT_US_EMAIL
      [CONTACT_US_EMAIL['to']]
    else
      ['success@musc.edu']
    end
  end

  it 'should get mailer from config' do
    if defined? CONTACT_US_EMAIL
      expect(CONTACT_US_EMAIL['cc']).to eq 'sparc@chpc.utah.edu'
      expect(CONTACT_US_EMAIL['to']).to eq 'sparc-admin@lists.utah.edu'
      expect(mail.cc).to eq ['sparc@chpc.utah.edu']
      expect(mail.to).to eq ['sparc-admin@lists.utah.edu']
    else
      fail 'need define contact_us_email in application.yml'
    end
  end

  it 'renders subject' do
    expect(mail.subject).to eq 'subject'
  end

  it 'renders the receiver email' do
    expect(mail.to).to eq(to)
  end

  it 'renders the receiver cc email' do
    expect(mail.cc).to eq(cc)
  end

  it 'renders the sender email' do
    expect(mail.from).to eq(['example@example.com'])
  end
end
