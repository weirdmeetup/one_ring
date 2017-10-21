class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :require_sign_in

  private

  def require_sign_in
    redirect_to sign_in_path unless session[:user_id]
  end

  def current_user
    User.find(session[:user_id])
  end
end
