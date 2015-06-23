# app/helpers/medium_helper.rb
module MediumHelper
	
	# Needs to render a different view depending on what the custom field type is
	# Single — Specifies that the field holds a single value
	# Map — Specifies that the field holds a map of key-value pairs
	# List — Specifes that the field holds an array of values
	# Localized — Specifies that a field with the String data type is a localized field

	# params
	# name 			string 		name of form input field
	# value 		mixed 		value to be shown
	# strcuture 	hash 		custom field structure of field
	# html_options 	hash 		html options to be displayed
	def custom_field(name, value, structure, html_options = {})
		case structure[:dataStructure].downcase
			when "single"
				case structure[:dataType].downcase
					when "boolean"
						boolean(name, value, html_options)
					when "integer"
						integer(name, value, html_options)
					else
						single(name, value, html_options)
				end
				
			when "map"
			when "list"
				list(name, value, html_options)
		end
	end

	private

	def single(name, value, html_options = {})
		text_field_tag name, value, html_options
	end

	def list(name, value, html_options = {})
		if value.present?
			text_field_tag name, value.join(","), html_options
		else
			text_field_tag name, "", html_options
		end
	end

	def map
	end

	def boolean(name, value, html_options = {})
		capture do
			concat hidden_field_tag name, "false", html_options.merge({"id" => "#{name}Hidden"})
			concat " "
			concat check_box_tag name, "true", value, html_options
		end
	end

	def integer(name, value, html_options)
		number_field_tag name, value, html_options
	end
end