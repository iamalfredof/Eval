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
		queue_size = Sidekiq::Queue.new("default").size + 
								 Sidekiq::Queue.new("pdf").size + 
								 Sidekiq::Queue.new("office").size + 
								 Sidekiq::Queue.new("crawler").size +
								 Sidekiq::Queue.new("ocr").size

		queue_size_msg = "QUEUE SIZE: #{queue_size}"
		
		if queue_size < 10
			"OK. #{queue_size_msg}"
		else
			"WARNING: TOO MANY JOBS ENQUEUED. #{queue_size_msg}"
		end
	end

	def latency
		queue_latency = Sidekiq::Queue.new.latency

		queue_latency_msg = "QUEUE LATENCY: #{queue_latency}"
		
		if queue_latency < 30
			"OK. #{queue_latency_msg}"
		else
			"WARNING: QUEUE LATENCY HIGH. #{queue_latency_msg}"
		end
	end

	def queue_process
		out = %x{ ps aux | grep sidekiq }
		out_msg = "OUT: #{out}"
		
		if out.include? 'sidekiq 4.1.2 udoczp2h'
			"OK. #{out_msg}"
		else
			%x{ bundle exec sidekiq -d -L sidekiq.log -q default -e production -c 5 }
			unless $?.exitstatus == 0
        "WARNING: SIDEKIQ COULD NOT RESTART. #{queue_health_msg}"
      end
			"OK. RESTARTING SIDEKIQ."
		end
	end

	def verify_security_token_get
  	unless params[:secret] == '64zNYufgM8dL1x506FY092uKbms23tT7'
  		render status: :forbidden, text: "You do not have access to this page."
  	end
  end

end