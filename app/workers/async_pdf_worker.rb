class AsyncPDFWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  sidekiq_options :queue => :pdf

  def perform(foreign_document_url, foreign_document_id, random_hex, 
  		bucket = ENV['S3_BUCKET'], callback_url = Constants.CALLBACK)
  	begin
    	service = DocumentService.new(foreign_document_url, foreign_document_id, random_hex, bucket)
    	result = service.start_routine
    	result ? respond(callback_url, 202, foreign_document_id, service.get_html_url, "success") :
    					 respond(callback_url, 422, foreign_document_id, nil, "something is wrong")
      Rails.logger.info result
  	rescue Exception => e
    	Rails.logger.error e.message
    	respond(callback_url, 422, foreign_document_id, nil, e.message)
  	end
  end

  private

  def respond(callback_url, _status, doc_id, url, message = '')
  	require 'httparty'
    HTTParty::Basement.default_options.update(verify: false)
    update_document(doc_id, url, _status != 202)

  	response = 
        HTTParty.post( callback_url,
          :body => {
          	"status"		=> _status,
            "c_message" => message,
            "document"  =>{
              'id' 			 => doc_id.to_s, 
              'html_url' => url,
              'secret'	 => Constants.TOKEN     
            }
          }
        )
    Rails.logger.info response
  end

  def update_document(doc_id, html_url, failed = false)
  	document = Document.find_by(id: doc_id)
  	document.update_attributes(html_url: html_url, failed_processing: failed) if document
  end
  
end