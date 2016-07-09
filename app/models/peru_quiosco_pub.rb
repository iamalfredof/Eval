class PeruQuioscoPub < ActiveRecord::Base
	validates :pq_firstpage_id, uniqueness: true

	after_create :upload_file

	def upload_file
		# Worker here to upload the file
		PeruQuioscoUploaderWorker.perform_async(self.id) 
	end

	def schedule_pq(product, offset)
		# 5am + 5 minutes in Lima
		PeruQuioscoWorker.perform_at(Time.new.utc.at_beginning_of_day + 1.day + 10.hours + 5.minutes + offset.minutes, product, offset)
	end

end