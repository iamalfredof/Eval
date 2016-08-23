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
		if params[:product].present? and params[:offset].present?
			PeruQuioscoWorker.perform_async( params[:product], Integer( params[:offset] ) )
		else
			render status: :forbidden, text: "You do not have access to this page."
		end
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
		detect_similar_titles

		@num_docs = Document.all.count
	end

private

	# Find documents with same title and delete all but
	# but the oldest one with +- 10 records
	def detect_similar_titles
		documents = Document.all
		similars = {}

		documents.each do |d|
			title = d.foreign_document_url.split('%2F').last
			
			if similars.has_key?( title )
				similars[title] = [ similars[title],d ].flatten
			else
				similars[title] = d
			end

		end

		@delete_candidates = []
		similars.each do |tuple|
			if tuple[1].class == Array
				@delete_candidates << tuple[1]
			end
		end

		@delete_candidates.each do |arr|
			arr.each do |doc|
				status_code = JSON.parse(
												HTTParty.get('https://www.udocz.com/api/v1/get_document/' + 
													doc.foreign_document_id.to_s + '.json')
												.body)['status']
				if status_code == 404
					Document.find(doc.id).destroy
				end
			end
		end

	end

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