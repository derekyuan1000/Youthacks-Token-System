class AdminsController < ApplicationController
  before_action :require_admin, except: [:new, :create, :verify_code, :confirm_code]

  def new
    # Signup form
  end

  def create
    name = params[:name].strip
    password = params[:password]
    password_confirmation = params[:password_confirmation]
    email = params[:email]

    if name.present? && password.present? && password == password_confirmation && email.present?
      code = rand(100_000..999_999).to_s
      AdminMailer.send_code(email, code).deliver_now

      session[:pending_admin] = {
        name: name,
        password: password,
        email: email,
        code: code
      }

      redirect_to verify_code_path
    else
      redirect_to signup_path, alert: 'Please fill all fields correctly.'
    end
  end

  def verify_code
    unless session[:pending_admin].present?
        redirect_to signup_path, alert: 'Please start the signup process first.'
    # Form for user to enter the code
    end
  end

  def confirm_code
    entered_code = params[:code]
    if session[:pending_admin].present? && session[:pending_admin][:code] == entered_code
      result = Admin.new!(name: session[:pending_admin][:name], password: session[:pending_admin][:password])
      if result[:success]
        session[:pending_admin] = nil
        redirect_to login_path, notice: 'Admin was successfully created.'
      else
        redirect_to signup_path, alert: result[:message]
      end
    else
      flash[:alert] = 'Invalid code. Please try again.'
      redirect_to verify_code_path
    end
  end

  # ... your other controller actions here ...

  private

  def require_admin
    unless session[:admin_id].present? && Admin.exists?(session[:admin_id])
      session[:admin_id] = nil
      redirect_to login_path
      return
    end
    @admin = Admin.find(session[:admin_id])
  end
end
