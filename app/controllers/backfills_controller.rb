class BackfillsController < ApplicationController
	before_action :verify_security_token_get, only: [:init_hn_worker, :delete_all_hn_posts, :hn_upload,
																									 :init_pq_worker, :pq_upload,
																									 :init_fp_worker,
																									 :backfill_all_mobile_pages
																									]

	def index
		BackfillWorker.perform_async
	end

	def init_fp_worker
		ForosPeruWorker.perform_async('*pdf*')
		ForosPeruWorker.perform_in(2.seconds, '*scribd*')
		ForosPeruWorker.perform_in(4.seconds,'*slideshare*')
		ForosPeruWorker.perform_in(6.seconds,'apuntes')
		ForosPeruWorker.perform_in(8.seconds,'libros')
	end

	def backfill_all_mobile_pages
		BackfillAllMobilePagesWorker.perform_async
	end

	def init_hn_worker
		HackerNewsWorker.perform_async
	end

	def init_pq_worker
		PeruQuioscoWorker.perform_async( 'elcomercio', 0 )
		PeruQuioscoWorker.perform_async( 'correo', 1 )
		PeruQuioscoWorker.perform_async( 'peru21', 2 )
		PeruQuioscoWorker.perform_async( 'gestion', 3 )
		PeruQuioscoWorker.perform_async( 'depor', 4 )
	end

	def hn_upload
		HackerNewsPost.find(params[:id]).upload_file
	end

	def pq_upload
		PeruQuioscoPub.find(params[:id]).upload_file
	end

	def delete_all_hn_posts
		HackerNewsPost.delete_all
	end

	def clean_data
		@prev_num_docs = Document.all.count

		delete_nulls
		keep_only_highest_id
		CleanMissingDocumentsWorker.perform_async

		@num_docs = Document.all.count
	end

private

	# Delete all but the one record with the highest id
	def keep_only_highest_id
		documents = Document.all

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

	# First delete nulls
	def delete_nulls
		documents = Document.all

		documents.each do |d|
			if d.html_url == nil
				d.destroy
			end
		end
	end

	def verify_security_token_get
  	unless params[:secret] == '64zNYufgM8dL1x506FY092uKbms23tT7'
  		render status: :forbidden, text: "You do not have access to this page."
  	end
  end

end