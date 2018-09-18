class SessionsController < ApplicationController
  # GET /sessions/new
  def new
  end

  # POST /sessions
  # POST /sessions.json
  def create
    user = User.find_by(email: params[:email])
    if user.authenticate(params[:password])
      cookies.encrypted[:user_id] = user.id
      redirect_to user_path(user), notice: 'Session was successfully created.'
    else
      render :new
    end
  end

  # DELETE /sessions/1
  # DELETE /sessions/1.json
  def destroy
  end

  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def session_params
      params.require(:session).permit(:email, :password)
    end
end
