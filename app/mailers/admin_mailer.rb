class AdminMailer < ApplicationMailer
    def send_code(email, code)
        puts email,code
        Rails.logger.info "Attempting to send email to #{email} with code #{code}"
        @code = code
        mail(to: email, subject: 'Your Admin Signup Confirmation Code')
    end
end
