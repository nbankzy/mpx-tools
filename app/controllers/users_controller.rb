class UsersController < ApplicationController

	layout 'users'

	def index
	end

	def login
		params.permit(:username, :password)	
		require_dependency 'theplatform' # `require_dependency` stops the module from caching
		mpx = Theplatform::Mpx.new
		auth = mpx.authorise(username: params[:username], password: params[:password])
		if auth['isException']
			redirect_to root_path, :notice => auth['description']
		elsif auth[:access_token].present?
			session[:token] = auth[:access_token]
			session[:idle] = Time.now + (auth[:idle_timeout]/(1000*60)).minutes
			session[:idle_duration] = auth[:idle_timeout]
			redirect_to medium_index_path
		else
			redirect_to root_path, :notice => "Unexpected error"
		end
	end

	def logout
		reset_session
		redirect_to root_path # redirect user back to home page users#index
	end

	def account
		params.required(:account)
		session[:account] = params[:account]
		redirect_to :back, :notice => "Account has been changed"
	end

end