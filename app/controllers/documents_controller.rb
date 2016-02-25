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
      	processor = DocumentProcessor.new(@document.document_url, @document.foreign_document_id)
      	html_url = processor.start_routine
      	unless html_url
      		format.json { render json: @document, status: :processing_failed }
      	else
      		@document.update_attribute(:html_url, html_url)
        	format.json { render :show, status: :created, location: @document }
      	end
      else
        format.json { render json: @document.errors, status: :unprocessable_entity }
      end
    end
	end

	# GET /documents/1.json
	def show
		@document = Document.find(params[:id])
	end

private
	def document_params
		params.require(:document).permit(
							:foreign_document_id, :document_url
  					 )
	end

end