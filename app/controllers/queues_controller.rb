class QueuesController < ApplicationController
	before_action :verify_security_token_get, only: [:start_queue
																									]

	def check_sidekiq
		render json: {
			queue_size: health,
			latency: latency,
			process: queue_process
			}.to_json
	end

private
	
	def health
		queue_size = Sidekiq::Queue.new.size
		queue_size_msg = "QUEUE SIZE: #{queue_size}"
		
		if queue_size < 50
			queue_health_msg = "OK. #{queue_size_msg}"
		else
			queue_health_msg = "WARNING: TOO MANY JOBS ENQUEUED. #{queue_size_msg}"
		end
	end

	def latency
		queue_latency = Sidekiq::Queue.new.latency

		queue_latency_msg = "QUEUE LATENCY: #{queue_latency}"
		
		if queue_latency < 30
			queue_health_msg = "OK. #{queue_latency_msg}"
		else
			queue_health_msg = "WARNING: QUEUE LATENCY HIGH. #{queue_latency_msg}"
		end
	end

	def queue_process
		queue_size = Sidekiq::Queue.all.size
		queue_size_msg = "QUEUE SIZE: #{queue_size}"
		
		if queue_size > 0
			queue_health_msg = "OK. #{queue_size_msg}"
		else
			%x{ bundle exec sidekiq -d -L sidekiq.log -q default -e production -c 20 }
			queue_health_msg = "WARNING: NO QUEUES DETECTED. #{queue_size_msg}"
		end
	end

	def verify_security_token_get
  	unless params[:secret] == '64zNYufgM8dL1x506FY092uKbms23tT7'
  		render status: :forbidden, text: "You do not have access to this page."
  	end
  end

end