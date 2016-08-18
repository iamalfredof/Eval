require 'uri'
require 'open-uri'
require 'fileutils'

class DocumentProcessorMobile
  attr_reader :url, :root_folder, :folder, :document_id, :html_url, :base_page_path, :thread_count, :file_path_opt
  attr_accessor :file_path, :pages_processed
  # attr_accessor :files

  # Initialize the processor class
  #
  # folder_path - path to the folder that you want to upload
  #
  # Examples
  #   => processor = DocumentProcessor.new("some_route/pdf_file")
  # 
  #
  def initialize(url, document_id, random_hex, thread_count = 5)
  	@thread_count     = thread_count
    @pages_processed  = 0
    @url 						 	= url
    @file_path       	= URI(url).path.split('/').last
    @file_path_opt    = document_id.to_s + '_opt.pdf'
    @folder           = document_id.to_s + '-' + random_hex
    @root_folder			= 'documents_html'
    @document_id 			= document_id.to_s
    @base_page_path   = document_id.to_s + '_mobile_page_'
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
  	unless download!
  		Rails.logger.error 'Download subroutine failed'
  		return false
  	end
    unless fix_pdf!
      Rails.logger.error 'Fix pdf subroutine failed'
      return false
    end
    unless process_mobile_pages!
      Rails.logger.error 'Process plain text subroutine failed'
      return false
    end
  	unless upload!
  		Rails.logger.error 'Upload subroutine failed'
  		return false
  	end
  	unless clean_up!
  		Rails.logger.error 'Clean up subroutine failed'
  		return false
  	end
    # unless trigger_callback
    #   Rails.logger.error 'Trigger callback subroutine failed'
    #   return false
    # end
  	return html_url
  end

  # public: Gets the html_url up front. Helps with requests timing out.
  #
  # Examples
  #   => processor.get_html_url
  #    'http://bucket.s3-website-region.amazonaws.com/root_folder/folder/id_opt.html'
  #
  # Returns html_url when finished
  def get_html_url 
    return html_url
  end

private

  # private: Download pdf in location
  #
  # Examples
  #   => processor.download!
  #     true
  #
  # Returns true when finished downloading
  def fix_pdf!
    %x( gs -o #{file_path_opt} -sDEVICE=pdfwrite -dPDFSETTINGS=/prepress #{file_path} )
    unless $?.exitstatus == 0
      Rails.logger.error "Failed at fix pdf. Command: gs -o #{file_path_opt} -sDEVICE=pdfwrite -dPDFSETTINGS=/prepress #{file_path}"
    end

    File.delete( file_path )
    @file_path = file_path_opt
  end

  # private: Process document in location for plain text
  #
  # Examples
  #   => processor.process!
  #     true
  #
  # Returns true when finished the process
  def process_mobile_pages!
    %x( mkdir #{folder} )
    unless $?.exitstatus == 0
      Rails.logger.error "Failed at making directory."
    end

    # pages             = PDF::Reader.new(file_path).pages.to_ary
    # page_count        = pages.size

    # pages_processed   = 0
    # mutex             = Mutex.new
    # threads           = []

    # thread_count.times do |i|
    #   threads[i] = Thread.new {
    #     until pages.empty?
    #       mutex.synchronize do
    #         pages_processed += 1
    #       end
    #       page = pages.pop rescue nil
    #       next unless page

    #       fetch_page!(page.number)
    #     end
    #   }
    # end

    # threads.each { |t| t.join }

    pages             = PDF::Reader.new(file_path).page_count
    for i in 1..pages
      fetch_page!(i)
    end

    Rails.logger.info( 'Processed id-' + document_id + ' mobile pages: ' + pages_processed.to_s + '/' + page_count.to_s )
    return true
  end

  def fetch_page!(page_number)
    begin
      Magick::Image.read( file_path + '[' + (page_number - 1).to_s + ']' )
      .first
      .write( folder + '/' + base_page_path + page_number.to_s + '.png' )
      @pages_processed += 1
    rescue Magick::ImageMagickError => e
      Rails.logger.error e.to_s
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
	    Rails.logger.info 'Downloaded file'
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
  	Rails.logger.info 'Uploaded file'
  	return true
  end

  # private: Cleans up the generated files and folders in location
  #
  # Examples
  #   => processor.cleanup!
  #     true
  #
  # Returns true when finished uploading
  def clean_up!(non_optimized = false)
    File.delete( file_path )
    FileUtils.rm_rf( folder )
    Rails.logger.info 'Cleaned up'
    return true
  end

  # private: Callsback a POST request to the udocz.com
  #
  # Examples
  #   => processor.trigger_callback
  #     true
  #
  # Returns true when finished uploading
  # def trigger_callback
  #   response = open('https://www.udocz.com/api/v1/pdf_processing_callback/' + document_id + '.json', {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}).read
  #   Rails.logger.info 'Normal PDF Callback to uDocz'
  #   return true
  # end

end