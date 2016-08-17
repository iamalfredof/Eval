class ProcessMobilePagesWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  def perform(document_id)
  	d = Document.find(document_id)
  	random_hex = d.html_url.split('/')[4].split('-').last
		dpm = DocumentProcessorMobile.new(
						d.foreign_document_url,
						d.foreign_document_id,
						random_hex, 
						50
					)
		dpm.start_routine
  end

end