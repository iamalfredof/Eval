require 'uri'
require 'open-uri'
require 'fileutils'

class DocumentProcessor
  attr_reader :url, :file_path, :file_path_opt, :root_folder, :folder, :document_id, :html_url
  # attr_accessor :files

  # Initialize the processor class
  #
  # folder_path - path to the folder that you want to upload
  #
  # Examples
  #   => processor = DocumentProcessor.new("some_route/pdf_file")
  # 
  #
  def initialize(url, document_id)
  	@url 						 	= url
    @file_path       	= URI(url).path.split('/').last
    @file_path_opt	 	= document_id.to_s + '_opt.pdf'
    @root_folder			= 'documents_html'
    @folder		 				= document_id.to_s + '-' + SecureRandom.hex
    @document_id 			= document_id.to_s
    @html_url					= "http://#{ENV['S3_BUCKET']}.s3-website-#{ENV['AWS_REGION']}.amazonaws.com/#{@root_folder}/#{@folder}/#{@document_id}_opt.html"
  end

	# public: Runs the whole routine
  #
  # Examples
  #   => processor.start_routine
  #    'http://bucket.s3-website-region.amazonaws.com/root_folder/folder/id_opt.html'
  #
  # Returns html_url when finished
  def start_routine 
  	download!
  	process!
  	upload!
  	clean_up!
  	return html_url
  end

private

  # private: Process document in location
  #
  # Examples
  #   => processor.process!
  #     true
  #
  # Returns true when finished the process
  def process!
  	%x( gs -sDEVICE=pdfwrite -sOutputFile='#{file_path_opt}' -dNOPAUSE -dBATCH #{file_path} )
  	unless $?.exitstatus == 0
  		puts 'Failed at optimizing pdf'
  		return false
  	end
  	%x( pdf2htmlEX --fit-width 1024 --split-pages 1 --dest-dir #{folder} #{file_path_opt} )
  	unless $?.exitstatus == 0
  		puts 'Failed at converting pdf to html'
  		return false
  	else
  		puts 'Processed file'
  		return true
  	end
  end

  # private: Download pdf in location
  #
  # Examples
  #   => processor.download!
  #     true
  #
  # Returns true when finished downloading
  def download!
		open(file_path, 'wb') do |file|
		  file << open(url).read
	    puts 'Downloaded file'
	    return true
		end
  end

  # private: Uploads document in location
  #
  # Examples
  #   => processor.upload!
  #     true
  #
  # Returns true when finished uploading
  def upload!
  	uploader = S3FolderUpload.new(folder)
  	uploader.upload!(50, root_folder + '/')
  	puts 'Uploaded file'
  	return true
  end

  # private: Cleans up the generated files and folders in location
  #
  # Examples
  #   => processor.cleanup!
  #     true
  #
  # Returns true when finished uploading
  def clean_up!
    File.delete( file_path )
    File.delete( file_path_opt )
    FileUtils.rm_rf( folder )
    puts 'Cleaned up'
    return true
  end

end