class MediumController < SessionsController

	before_action :mpx_setup
	helper_method :is_ssl?

	def index

		if params[:query].present?
			@media = @mpx.retrieve('media', '', {q: params[:query]})
		else
			@media = @mpx.retrieve('media')
		end
		# render :text => @media
	end

	def create
	end

	def new
	end

	def edit
		@media = @mpx.retrieve('media', params[:id], {:form => "cjson", :pretty => 'true'})
		@categories = @mpx.retrieve('category', '', {:form => "cjson", :pretty => 'true'})
		@customFields = @mpx.customFields('', {:form => "json", :pretty => 'true', :schema => '1.6'})
		# @customFields = @mpx.retrieve('Media/Field', '', {:form => "json", :pretty => 'true', :schema => '1.6'})
		# render json: @customFields.body
	end

	def show
		@media = @mpx.retrieve('media', params[:id], {:form => "json", :pretty => 'true'})
		@customFields = @mpx.retrieve('Media/Field', '', {:form => "json", :pretty => 'true', :schema => '1.6'})

		# render json: @customFields.body
	end

	def update
		params.require(:media)
		updateFields = params[:media].except('id')
		categories = params[:media][:categories]
		catTemp = Array.new
		categories.each do |c|
			item = {:name => c}
			catTemp.push(item)
		end
		updateFields["categories"] = catTemp

		returned = @mpx._modifyMetadata(updateFields)
		# render text: returned
		response = @mpx.update(params[:media][:id], returned)
		# render json: response
		redirect_to medium_path(params[:id]), :notice => "Media updated"
	end

	def destroy
	end

	private

		def mpx_setup
			require_dependency 'theplatform' # `require_dependency` stops the module from caching
			@mpx = Theplatform::Media.new
			@mpx.token = session[:token]
			@mpx.account = session[:account]
		end


		def is_ssl?
			request.ssl?
		end
end