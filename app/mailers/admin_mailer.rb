class AdminMailer < ApplicationMailer
    def send_code(email, code)
        @code = code
        mail(to: email, subject: 'Your Email Confirmation Code for Aha!')
    end
end
