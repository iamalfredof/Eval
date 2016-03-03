class DocumentsController < ApplicationController

	# GET /documents.json
	def index
		@documents = Document.all
	end

	# POST /documents.json
	def create
		@document = Document.create(document_params)

		respond_to do |format|
      if @document.save
      	random_hex = SecureRandom.hex
      	DocumentWorker.perform_async(@document.foreign_document_url, @document.foreign_document_id, random_hex)
      	dp = DocumentProcessor.new(@document.foreign_document_url, @document.foreign_document_id, random_hex)
      	html_url = dp.get_html_url
    		@document.update_attribute(:html_url, html_url)
      	format.json { render :show, status: :created, location: @document }
      else
        format.json { render json: @document.errors, status: :unprocessable_entity }
      end
    end
	end

	# GET /documents/1.json
	def show
		@document = Document.where(:foreign_document_id => params[:id]).first
	end

	# GET /documents/:id/search:query
	def search
		dws = DocumentWordSearch.new
		data = dws.search( params[:id], params[:query] )
		render json: {:array => data}
	end

private
	def document_params
		params.require(:document).permit(
							:foreign_document_id, :foreign_document_url
  					 )
	end

end