class SessionsController < ApplicationController

	before_action :logged_in
	before_action :mpx_accounts

	private

	def logged_in
		if session[:token].present?
			if session[:idle] < Time.now
				reset_session
				redirect_to root_path, :notice => "Session token has expired"
			else
				session[:idle] = Time.now + (session[:idle_duration]/(1000*60)).minutes 
			end
		else
			redirect_to root_path
		end
	end

	def mpx_accounts
		require_dependency 'theplatform' # `require_dependency` stops the module from caching
		mpx = Theplatform::Mpx.new
		mpx.token = session[:token]
		@accounts = mpx.accounts({:sort => 'title'})
		if !session[:account].present? # if account is not set, set to first
			session[:account] = @accounts['entries'][0]['id']
		end
	end

end