require 'uri'
require 'open-uri'
require 'fileutils'

class DocumentProcessor
  attr_reader :url, :file_path_opt, :file_path_txt, :root_folder, :folder, :document_id, :html_url
  attr_accessor :file_path, :office_flag, :non_optimized
  # attr_accessor :files

  # Initialize the processor class
  #
  # folder_path - path to the folder that you want to upload
  #
  # Examples
  #   => processor = DocumentProcessor.new("some_route/pdf_file")
  # 
  #
  def initialize(url, document_id, random_hex)
  	@url 						 	= url
    @file_path       	= document_id.to_s + '.' + URI(url).path.split('.').last
    @file_path_opt	 	= document_id.to_s + '_opt.pdf'
    @file_path_txt    = document_id.to_s + '.txt'
    @folder           = document_id.to_s + '-' + random_hex
    @root_folder			= 'documents_html'
    @document_id 			= document_id.to_s
    @html_url					= "http://#{ENV['S3_BUCKET']}.s3-website-#{ENV['AWS_REGION']}.amazonaws.com/#{@root_folder}/#{@folder}/#{@document_id}_opt.html"
    @office_flag      = false
    @non_optimized    = false
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
  	unless process!(non_optimized)
  		Rails.logger.error 'Process subroutine failed'
  		return false
  	end
    unless process_plain_text!
      Rails.logger.error 'Process plain text subroutine failed'
      return false
    end
  	unless upload!
  		Rails.logger.error 'Upload subroutine failed'
  		return false
  	end
  	unless clean_up!(non_optimized)
  		Rails.logger.error 'Clean up subroutine failed'
  		return false
  	end
    unless trigger_callback
      Rails.logger.error 'Trigger callback subroutine failed'
      return false
    end
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

  # public: Processes a plain text copy of the pdf
  #
  # Examples
  #   => processor.process_plain_text_ocr!
  #     true
  #
  # Returns true when finished
  def process_plain_text_ocr!
    unless download!
      Rails.logger.error 'Download subroutine failed'
      return false
    end
    unless process_plain_text!( true, true )
      Rails.logger.error 'Process plain text subroutine failed'
      return false
    end
    unless upload!
      Rails.logger.error 'Upload subroutine failed'
      return false
    end
    unless trigger_callback_ocr
      Rails.logger.error 'Trigger callback subroutine failed'
      return false
    end
    File.delete( file_path )
    FileUtils.rm_rf( folder )

    Rails.logger.info 'Cleaned up'
    Rails.logger.info 'Processed plain text'
    return true
  end

  # public: Processes a plain text copy of the pdf
  #
  # Examples
  #   => processor.process_plain_text
  #     true
  #
  # Returns true when finished
  def process_plain_text_backfill!
    unless download!
      Rails.logger.error 'Download subroutine failed'
      return false
    end
    unless process_plain_text!( true, false )
      Rails.logger.error 'Process plain text subroutine failed'
      return false
    end
    unless upload!
      Rails.logger.error 'Upload subroutine failed'
      return false
    end
    File.delete( file_path )
    FileUtils.rm_rf( folder )

    Rails.logger.info 'Cleaned up'
    Rails.logger.info 'Processed plain text'
    return true
  end

  def process_non_optimized!
    unless download!
      Rails.logger.error 'Download subroutine failed'
      return false
    end
    unless process!(true)
      Rails.logger.error 'Process subroutine failed'
      return false
    end
    unless upload!
      Rails.logger.error 'Upload subroutine failed'
      return false
    end
    unless clean_up!(true)
      Rails.logger.error 'Clean up subroutine failed'
      return false
    end
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
  def process!(non_optimized = false)
    # Detects office extensions
    # Converts to pdf
    # Cleans office file from file system
    # Makes a copy of the pdf to the upload folder
    office = OfficeProcessor.new(file_path)
    if office.is_office?
      if office.start_routine
        file_name_arr  = file_path.split('.')
        file_name_arr.last.replace('pdf')
        @file_path  = file_name_arr.join('.')
  
        @office_flag = true
      else
        Rails.logger.error "Office processor failed. document_id: #{document_id} file_path: #{file_path}"
        return false
      end
    end

    # By pass the optimization feature upon special request
    if non_optimized
      # @file_path_opt = file_path
      File.rename(file_path, file_path_opt)
    else
      %x( gs -sDEVICE=pdfwrite -sOutputFile='#{file_path_opt}' -dNOPAUSE -dBATCH #{file_path} )
    	unless $?.exitstatus == 0
    		Rails.logger.error "Failed at optimizing pdf. Command: gs -sDEVICE=pdfwrite -sOutputFile='#{file_path_opt}' -dNOPAUSE -dBATCH #{file_path}"
    		Rails.logger.info "Moving on with unoptimized file."
        File.rename(file_path, file_path_opt)
        @non_optimized = true
    	end
    end
  	%x( pdf2htmlEX --fit-width 1024 --split-pages 1 --dest-dir #{folder} #{file_path_opt} )
  	unless $?.exitstatus == 0
  		Rails.logger.error "Failed at converting pdf to html. Command: pdf2htmlEX --fit-width 1024 --split-pages 1 --dest-dir #{folder} #{file_path_opt}"
  		return false
  	end
    
    if office_flag
      simple_file_name = document_id + '.pdf'
      %x( cp #{file_path_opt} #{folder}/#{simple_file_name} )
      unless $?.exitstatus == 0
        Rails.logger.error "Failed at copying converted office2pdf to folder. Command: cp #{file_path_opt} #{folder}/#{simple_file_name}"
        return false
      end
    end

		Rails.logger.info 'Processed file'
		return true
  end

  # private: Process document in location for plain text
  #
  # Examples
  #   => processor.process!
  #     true
  #
  # Returns true when finished the process
  def process_plain_text!( backfill = false, ocr = false )
    if backfill
      %x( mkdir #{folder} )
      unless $?.exitstatus == 0
        Rails.logger.error "Failed at making directory."
      end
      n = PDF::Reader.new(file_path).page_count
    else
      n = PDF::Reader.new(file_path_opt).page_count
    end
    for i in 1..n
      if ocr
        # TODO: This will generate image versions so we need to clean them later
        %x( pdftoppm #{file_path_opt} -gray -r 300 -f #{i} -l #{i} -singlefile '#{folder}/#{i}_out' )
        unless $?.exitstatus == 0
          Rails.logger.error "Failed at pdf to ppm. Command: pdftoppm #{file_path_opt} -gray -r 300 -f #{i} -l #{i} -singlefile '#{folder}/#{i}_out'"
          return false
        end
        Rails.logger.info 'Out: ' + i.to_s + '_out.pgm'
        file_path_txt_stripped = file_path_txt.gsub('.txt','')
        %x( tesseract '#{folder}/#{i}_out.pgm' '#{folder}/#{i}_#{file_path_txt_stripped}' )
        unless $?.exitstatus == 0
          Rails.logger.error "Failed at OCR. Command: tesseract '#{folder}/#{i}_out.pgm' '#{folder}/#{i}_#{file_path_txt_stripped}'"
          return false
        end
        Rails.logger.info 'Out: ' + folder + '/' + i.to_s + '_' + file_path_txt
        # TODO: Clean pgm's here
        file_to_delete = folder + '/' + i.to_s + '_out.pgm'
        File.delete( file_to_delete )
      else
        %x( pdftotext -f #{i} -l #{i} #{file_path_opt} '#{folder}/#{i}_#{file_path_txt}' )
        unless $?.exitstatus == 0
          Rails.logger.error "Failed at processing plain text. Command: pdftotext #{file_path} '#{folder}/#{file_path_txt}'"
          return false
        end
      end
    end
    unless merge_txt_pages!(n)
       Rails.logger.error "Merging txt files failed."
      return false
    end
    %x( cp #{folder}/#{file_path_txt} ../../document_txt_cache )
    unless $?.exitstatus == 0
      Rails.logger.error "Failed at copying to cache. Command: cp #{folder}/#{file_path_txt} ../../document_txt_cache"
      return false
    else
      Rails.logger.info 'Processed plain text file'
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
  def merge_txt_pages!(n)
    File.open(folder + '/' + file_path_txt,'a') do |mergedFile|
      for i in 1..n
        # Read subfile
        lines = IO.readlines( folder + '/' + i.to_s + '_' + file_path_txt )
        for line in lines
          mergedFile << line
        end
        mergedFile << '<page-break>'
        File.delete( folder + '/' + i.to_s + '_' + file_path_txt )
      end
    end
    return true
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
    File.delete( file_path_opt )
    unless non_optimized
      File.delete( file_path )
    end
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
  def trigger_callback
    if office_flag
      response = open('https://www.udocz.com/api/v1/office_processing_callback/' + document_id + '.json', {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}).read
      Rails.logger.info 'Office callback to uDocz'
    else
      response = open('https://www.udocz.com/api/v1/pdf_processing_callback/' + document_id + '.json', {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}).read
      Rails.logger.info 'Normal PDF Callback to uDocz'
    end

    return true
  end

    # private: Callsback a POST request to the udocz.com
  #
  # Examples
  #   => processor.trigger_callback
  #     true
  #
  # Returns true when finished uploading
  def trigger_callback_ocr
    response = open('https://www.udocz.com/api/v1/ocr_callback/' + document_id + '.json', {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}).read
    Rails.logger.info 'OCR callback to uDocz'
    return true
  end

end