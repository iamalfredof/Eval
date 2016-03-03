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
		filename			= document_id.to_s + ".txt"
		document 			= Document.find(document_id)
		base_url			= document.html_url.split('/').pop.join('/') + '/'

		ls = %x( ls )
		# File in cache folder
		unless ls.include? filename
			open('../document_txt_cache/' + filename, 'wb') do |file|
			  file << open( base_url + filename ).read
			end
		end

		# Read file and build data
		lines = IO.readlines( '../document_txt_cache/' + filename )
		for line in lines
			if line.include? query
				data << { "p" => current_page, "t" => line  }
			end
	    if line["\f"]
	        current_page += 1
	    end
		end
		
		return data

	end

end