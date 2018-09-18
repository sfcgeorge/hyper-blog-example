class ApplicationController < ActionController::Base
  before_action :authenticate_from_session

  private

  attr_reader :current_user

  def authenticate_from_session
    if (user_id = cookies.encrypted[:user_id])
      @current_user = User.find(user_id)
    end
  end

  def authenticate_user
    redirect_to new_session_path unless @current_user
  end

  # NOTE: For Hyperloop. All that's needed to hook up auth.
  def acting_user
    current_user
  end
end
