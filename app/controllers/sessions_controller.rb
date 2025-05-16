class SessionsController < ApplicationController
  def new
    # Render login form
  end

  def create
    session_params = params.permit(:name, :password)
    @admin = Admin.find_by(name: session_params[:name])
    if @admin && @admin.authenticate(session_params[:password])
      session[:admin_id] = @admin.id
      redirect_to @admin
      puts "Admin authenticated successfully."
    else
      flash[:notice] = "Login is invalid!"
      redirect_to login_path
    end
  end

  def destroy
    session[:admin_id] = nil
    redirect_to login_path, notice: "Logged out"
  end
end
