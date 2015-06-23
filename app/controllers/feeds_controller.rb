class FeedsController < SessionsController

	layout 'application' # Render page container

	include HTTParty
	include Nokogiri

	before_action :retrieve_feeds, only: [:index, :show]
	after_action :check_params, only: [:index, :show]

	def index # GET
		feeds = Theplatform::Feed.new
		if @feeds.count > 0
			@media = feeds.retrieve(@feeds[0][:url], {:form => 'json', :pretty => 'true'})
		else
			@media = Array.new
		end
		
		if params['options'].nil?
			params['options'] = {}
		end
	end

	def show # POST
		@media = @mpx.retrieve(params[:feed], params[:options])
		@feed_url = @media.request.last_uri
		@format = params[:format]
	    render template: 'feeds/index', formats: 'html'
	end


	private

	def get_feed(feed, options = {})
		response = self.class.get(feed, :query => options)
	    response.body
	end

	def retrieve_feeds
		require_dependency 'theplatform' # `require_dependency` stops the module from caching
		@mpx = Theplatform::Feed.new
		@mpx.token = session[:token]
		@mpx.account = session[:account]
		@feeds = @mpx.all
	end

	def check_params
	end
end
