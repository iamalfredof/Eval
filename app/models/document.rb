class Document < ActiveRecord::Base

	after_save :queue_next_pending_backfill

	def queue_next_pending_backfill
		
		next_doc = Document.where(:backfilled => false).first

		ProcessMobilePagesWorker.perform_in(
					2.seconds
					next_doc.foreign_document_url,
					next_doc.foreign_document_id,
					next_doc.html_url.split('/')[4].split('-')[1]
				)

	end

end