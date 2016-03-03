class BackfillsController < ApplicationController

	def index
		BackfillWorker.perform_async
	end

	def clean_data
		# First delete nulls
		documents = Document.all
		documents.each do |d|
			if d.html_url == nil
				d.destroy
			end
		end

		# Delete all but the one record with the highest id
		documents.each do |d|
			fid = d.foreign_document_id
			# Find all with same foreign id
			similars = Document.where(:foreign_document_id => fid)
			highest_id = 0
			# Find latest record
			similars.each do |s|
				if s.id > highest_id
					highest_id = s.id
				end
			end
			# Delete all but latest record
			similars.each do |s|
				unless s.id == highest_id
					s.destroy
				end
			end
		end

	end

end