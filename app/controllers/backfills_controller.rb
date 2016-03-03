class BackfillsController < ApplicationController

	def index
		documents = Document.all
	
		documents.each do |d|
			random_hex = d.html_url.split('/')[4].split('-').last
			BackfillWorker.perform_async(d.foreign_document_url, d.foreign_document_id, random_hex)
		end
	end

end