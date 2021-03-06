require 'fileutils'
require 'open-uri'

class DocumentWordSearch


	# public: Downloads and searches the document for a query match
  #
  # Examples
  #   => processor.start_routine
  #    'http://bucket.s3-website-region.amazonaws.com/root_folder/folder/id_opt.html'
  #
  # Returns html_url when finished
	def search( document_id, query )
		current_page 	= 1		# Current page
		ocurrences 		= 0		# Number of matches for the query
		data 					= []	# Array to save the page number and line of the occurence
		cache_route		= '../../document_txt_cache'
		filename			= document_id.to_s + ".txt"
		document 			= Document.where(:foreign_document_id => document_id).first
		arr 					= document.html_url.split('/') # Split the url
		arr.pop				# Pop the last element
		base_url 			= arr.join('/') + '/' # Join the url again

		ls = %x( ls #{cache_route} )
		# File in cache folder
		unless ls.include? filename
			open( cache_route + '/' + filename, 'wb') do |file|
			  file << open( base_url + filename ).read
			end
		end

		# Read file and build data
		lines = IO.readlines( cache_route + '/' + filename )
		for line in lines
			if line["<page-break>"]
	        current_page += line.scan(/<page-break>/).count
	    end
			if line.downcase.include? query.downcase
				data << { "p" => current_page, "t" => line  }
			end
		end

		return data

	end

end