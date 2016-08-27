class QueuesController < ApplicationController
	before_action :verify_security_token_get, only: [:start_queue
																									]
	
	def health
		queue_size = Sidekiq::Queue.new.size
		queue_size_msg = "QUEUE SIZE: #{queue_size}"
		
		if queue_size < 50
		 queue_health_msg = "OK. #{queue_size_msg}"
		else
		 queue_health_msg = "WARNING: TOO MANY JOBS ENQUEUED. #{queue_size_msg}"
		end

		render json: { status: queue_health_msg }.to_json
	end

	def latency
		queue_latency = Sidekiq::Queue.new.latency

		queue_latency_msg = "QUEUE LATENCY: #{queue_latency}"
		
		if queue_latency < 30
		 queue_health_msg = "OK. #{queue_latency_msg}"
		else
		 queue_health_msg = "WARNING: QUEUE LATENCY HIGH. #{queue_latency_msg}"
		end

		render json: { status: queue_health_msg }.to_json
	end

	def queue_process
		queue_size = Sidekiq::Queue.all.size
		queue_size_msg = "QUEUE SIZE: #{queue_size}"
		
		if queue_size > 0
		 queue_health_msg = "OK. #{queue_size_msg}"
		else
		 queue_health_msg = "WARNING: NO QUEUES DETECTED. #{queue_size_msg}"
		end

		render json: { status: queue_health_msg }.to_json
	end

	def start_queue
		
	end

private

	def verify_security_token_get
  	unless params[:secret] == '64zNYufgM8dL1x506FY092uKbms23tT7'
  		render status: :forbidden, text: "You do not have access to this page."
  	end
  end

end