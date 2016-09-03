class DocumentsController < ApplicationController
  before_action :verify_security_token,
  	only: [:create]

  before_action :verify_security_token_get,
  	only: [:ocr, :pno, :process_mobile_pages]

	# GET /documents.json
	def index
		@documents = Document.all
	end

	def backfilled
		@pending_count = Document.where(:backfilled => false, :failed_processing => false).count
		@total_count = Document.all.count
		@success_count = Document.where(:backfilled => true, :failed_processing => false).count
		@failed_count = Document.where(:failed_processing => true).count
	end

	# POST /documents.json
	def create
		respond_to do |format|
      if @document.save
      	random_hex = SecureRandom.hex

      	# Process as office or as pdf
      	if OfficeProcessor.new( @document.foreign_document_url ).is_office?
      		OfficeWorker.perform_async(@document.foreign_document_url, @document.foreign_document_id, random_hex)
      	else
      		PDFWorker.perform_async(@document.foreign_document_url, @document.foreign_document_id, random_hex)
      	end

      	dp = DocumentProcessor.new(@document.foreign_document_url, @document.foreign_document_id, random_hex)
      	html_url = dp.get_html_url
    		@document.update_attribute(:html_url, html_url)
      	format.json { render :show, status: :created, location: @document }
      else
        format.json { render json: @document.errors, status: :unprocessable_entity }
      end
    end
	end

	def process_mobile_pages
		ProcessMobilePagesWorker.perform_async(@document.foreign_document_url, @document.foreign_document_id, @document.html_url.split('/')[4].split('-')[1])
		render json: {status: '200', processing_mobile_pages: 'Is a go'}.to_json
	end

	# GET /documents/1.json
	def show
		@document = Document.where(:foreign_document_id => params[:id]).first
	end

	# GET /documents/:id/search:query
	def search
		dws = DocumentWordSearch.new
		data = dws.search( params[:id], params[:query] )
		render json: data
	end

	# GET /documents/:id/ocr:secret
	def ocr
		OCRWorker.perform_async(@document.foreign_document_url, @document.foreign_document_id, @document.html_url.split('/')[4].split('-')[1])
		render json: {status: '200', ocr: 'Is disabled'}.to_json
	end

	# GET /documents/:id/non_optimized:secret
	def pno
		PNOWorker.perform_async(@document.foreign_document_url, @document.foreign_document_id, @document.html_url.split('/')[4].split('-')[1])
		render json: {status: '200', pno: 'Is a go'}.to_json
	end

private
	def document_params
		params.require(:document).permit(
							:foreign_document_id, :foreign_document_url, :secret
  					 )
	end

	def verify_security_token
		@document = Document.create(document_params)

  	unless @document.secret == '64zNYufgM8dL1x506FY092uKbms23tT7'
  		render status: :forbidden, text: "You do not have access to this page."
  	end
  end

  def verify_security_token_get
		@document = Document.where(:foreign_document_id => params[:id]).first

  	unless params[:secret] == '64zNYufgM8dL1x506FY092uKbms23tT7'
  		render status: :forbidden, text: "You do not have access to this page."
  	end
  end

end