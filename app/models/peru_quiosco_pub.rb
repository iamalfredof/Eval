class PeruQuioscoPub < ActiveRecord::Base
	validates :pq_firstpage_id, uniqueness: true

	after_create :upload_file

	def upload_file
		# Worker here to upload the file
		PeruQuioscoUploaderWorker.perform_async(self.id) 
	end

	def schedule_pq(product)
		PeruQuioscoWorker.perform_in(1.hour, product)
	end

end