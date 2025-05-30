class TestMailer < ApplicationMailer
    def sample_email(to_email)
        mail(to: to_email, subject: "Test Email from AWS SES") do |format|
            format.text { render plain: "This is a test email sent via AWS SES SMTP from Rails." }
        end
    end
end
