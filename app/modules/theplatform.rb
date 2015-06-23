# encoding: UTF-8

require 'httparty'

module Theplatform
	class Mpx
		require 'json'
		include HTTParty

		attr_reader :media, :feed, :account
		attr_accessor :access_token

		def authorise(params)
			begin
				self.class.base_uri 'https://identity.auth.theplatform.com/idm/web/Authentication'
				options = { query: { schema: '1.0', form: 'json' } }
				auth = { username: params[:username], password: params[:password] }

				options.merge!(body: auth)
				response =  self.class.post('/signIn', options)
				if response['isException']
					return response
				else
					@access_token = response['signInResponse']['token']
					@user_id = response['signInResponse']['userId']
					@account = params[:account] && !params[:account].empty? ? params[:account] : nil
					@idle = response['signInResponse']['idleTimeout']
				end
				{
					access_token: @access_token,
					user_id: @user_id,
					idle_timeout: @idle
				}
			rescue
			end
		end

		def account=(account)
			@account = account
		end

		def account
			self.class.base_uri 'http://access.auth.theplatform.com/data/Account'
			@options = {query: {schema: '1.2', form: 'cjson', token: @access_token}}
			response = 	self.class.get("/#{@account.split('/').last}", @options)
			JSON[response.body]
		end

		def accounts(options)
			self.class.base_uri 'http://access.auth.theplatform.com/data/Account'
			@options = {schema: '1.2', form: 'cjson', token: @access_token}
			@options.merge!(options)
			response = 	self.class.get("", :query => @options)
			JSON[response.body]
		end

		def token=(token)
			@access_token = token
		end

		# Account custom fields
		# @param string media_id id of custom field
		# @param hash options query parameters
		def customFields(media_id = '', options = {})
			self.class.base_uri 'http://data.media.theplatform.com/media/data/Media/Field'
			query = {
					:schema => "1.6",
					:form => "json",
					:token => @access_token,
					:account => @account
			}
			query.merge!(options)

			base_url = media_id.blank? ? "" : "/" + media_id.split('/').last
			response = 	self.class.get(base_url, :query => query)
			customFields = Hash.new
			if response['entryCount'].present? && response['entryCount'] > 0
				response['entries'].each do |field|
					customFields["pl1$#{field['plfield$fieldName']}"] = {
						:id => field['id'],
						:title => field['title'],
						:dataType => field['plfield$dataType'],
						:dataStructure => field['plfield$dataStructure'],
						:fieldName => field['plfield$fieldName'],
						:namespace => field['plfield$namespace']
					}
				end
			end
			customFields
		end
	end

	class Feed < Mpx

		include HTTParty

		def all # retrieve all feeds
			account_info = account
			@account_pid = account_info["pid"]
			# account.entries
			self.class.base_uri 'https://data.feed.theplatform.com/feed/data'
			options = { query: { schema: '1.0', form: 'cjson', pretty: 'true' } }
			auth = { token: @access_token, account: @account }

			options.merge!(body: auth)
			response =  self.class.post('/FeedConfig', options)
			feeds = JSON.parse(response.body)
			feed_list = Array.new
			feeds["entries"].each { |x|
				item = {
						title: x['title'],
						url: "http://feed.theplatform.com/f/#{@account_pid}/#{x['pid']}"
					}
				feed_list.push(item)
			}
			feed_list
		end

		def retrieve(feed, options = {})
			response = self.class.get(feed, :query => options)
		    # response
		end

	end

	class Media < Mpx

		include HTTParty

		def create(title)
			self.class.base_uri 'http://data.media.theplatform.com/media/data/Media'
			req_payload = {
				"$xmlns" => {
			        "media" => "http://search.yahoo.com/mrss/",
			        "pl" => "http://xml.theplatform.com/data/object",
					"pl1" => @account,
			        "plmedia" => "http://xml.theplatform.com/media/data/Media"
				},
				"title" => title
			}
			@options = {
				query: {schema: '1.2', form: 'cjson', token: @token, account: @account}
			}
			response = self.class.post('', :query => @options[:query], :body => req_payload.to_json, :headers => { 'Content-Type' => 'application/json' })
			JSON[response.body]
		end

		def update(media_id, data)
			self.class.base_uri 'http://data.media.theplatform.com/media/data/Media'
			req_payload = {
				"$xmlns" => {
					"media" => "http://search.yahoo.com/mrss/",
					"pl" => "http://xml.theplatform.com/data/object",
					"pl1" => @account,
					"plmedia" => "http://xml.theplatform.com/media/data/Media",
			        "plfile" => "http://xml.theplatform.com/media/data/MediaFile",
			        "plrelease" => "http://xml.theplatform.com/media/data/Release"
				},
				"id" => media_id
			}
			options = {
				query: {schema: '1.2', form: 'cjson', token: @access_token, account: @account, pretty: true}
			}
			req_payload.merge!(data) # add metadata to request
			response = self.class.post('', :query => options[:query], :body => req_payload.to_json, :headers => { 'Content-Type' => 'application/json' })
			JSON[response.body]

		end

		def retrieve(url_prefix, media_id = "", options = {})
			self.class.base_uri 'http://data.media.theplatform.com/media/data/' + url_prefix.titleize
			query = {
					:schema => "1.2",
					:form => "cjson",
					:token => @access_token,
					:account => @account
			}
			query.merge!(options)

			base_url = media_id.blank? ? "" : "/" + media_id.split('/').last
			response = 	self.class.get(base_url, :query => query)
		end

		def categories(media_id = "", options = {})
			self.class.base_uri 'http://data.media.theplatform.com/media/data/Category'
			query = {
					:schema => "1.2",
					:form => "json",
					:token => @access_token,
					:account => @account
			}
			query.merge!(options)

			base_url = media_id.blank? ? "" : "/" + media_id.split('/').last
			response = 	self.class.get(base_url, :query => query)
		end

		def copy_file(media_id, file_url, file_settings = {})
			self.class.base_uri 'http://fms.theplatform.com/web/FileManagement'

			req_payload = {
				copyNewFiles: {
			        mediaId: media_id,
			        sourceFiles: [
			        	{sourceUrl: file_url}
			        ],
					mediaFileSettings: [
						file_settings
						# {
						# 	mediaFileInfo: {
						# 		assetTypes: ["Mezzanine"]
						# 	}
						# }
					]
				}
			}
			@options = {
				query: {schema: '1.5', form: 'json', token: @token, account: @account}
			}
			response = self.class.post('', :query => @options[:query], :body => req_payload.to_json, :headers => { 'Content-Type' => 'application/json' })
			JSON[response.body]
		end

		def publish(media_id)
			self.class.base_uri 'http://publish.theplatform.com/web/Publish'
			req_payload = {
				"publish" => {
					"mediaId" => media_id,
					"profileId" => @publish_profile
				}
			}
			@options = {
				query: {schema: '1.2', form: 'json', token: @token, account: @account}
			}

			response = self.class.post('', :query => @options[:query], :body => req_payload.to_json, :headers => { 'Content-Type' => 'application/json' })
			JSON[response.body]
		end

		def delete(media_id)
			self.class.base_uri 'http://data.media.theplatform.com/media/data/Media'
			media_id = media_id.split('/').last
			@options = {
				query: {schema: '1.2', form: 'cjson', token: @token, account: @account, 'byId' => media_id}
			}
			response = self.class.delete('', :query => @options[:query])
			JSON[response.body]
		end

		# private 

		def _modifyMetadata(metadata = {}) 
			# fetch custom fields for account
			customFields = self.customFields('', {:form => "json", :pretty => 'true', :schema => '1.6'})
			# loop each metadata entry
			metadata.each do |key, value|
				# does the value have any input
				if !value.blank?
					# does the key exist in customFields
					if customFields.has_key?(key)
						custom = customFields[key]
						case custom[:dataStructure].downcase
							when "single"
								case custom[:dataType].downcase
									when "boolean"
										if value == "true"
											metadata[key] = true
										elsif value == "false"
											metadata[key] = false
										else
											metadta[key] = "dunnoey"
										end
										# no else condition, if value is not a bool, don't save it
									when "integer"
										metadata[key] = value.to_i
								end
								
							when "map"
							when "list"
								metadata[key] = value.split(',').collect{|x| x.strip}
						end


					else
						#puts "it has no key #{key}"
					end
				else
				end
			end
		end

	end
end