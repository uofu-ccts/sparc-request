class ContactMailer < ApplicationMailer

  def contact_us_email(contact_form)
    @contact_form = contact_form
    if defined? CONTACT_US_EMAIL
      to = CONTACT_US_EMAIL['to']
      cc = CONTACT_US_EMAIL['cc']
    else
      to = 'success@musc.edu'
      cc = 'sparcrequest@gmail.com'
    end
    mail(to: to, cc: cc, from: "#{contact_form.email}", subject: "#{contact_form.subject}")
  end
end
