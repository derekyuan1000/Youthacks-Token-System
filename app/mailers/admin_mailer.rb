class AdminMailer < ApplicationMailer
    def send_code(email, code)
        puts email,code
        @code = code
        mail(to: email, subject: 'Your Admin Signup Confirmation Code')
    end
end
