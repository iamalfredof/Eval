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
		restart_msg = "OK. RESTARTING SIDEKIQ:"
		restart_failed_message = "WARNING:"
		restart_failed = false

		if out.scan(/sidekiq 4.1.2 udoczp2h/).count == 5
			"OK. #{out_msg}"
		else
			
			active_queues = []
			Sidekiq::Queue.all.each do |q|
				active_queues << q.name
			end

			queue_names = { "default" => "5", "pdf" => "5", "office" => "1", "crawler" => "1", "ocr" => "1" }
			queue_names.each do |q_name, q_concurrency|

				if active_queues.include? q_name
					restart_msg += " QUEUE OK: #{q_name}"
				else
					%x{ bundle exec sidekiq -d -L sidekiq.log -q #{q_name} -e production -c #{q_concurrency} }
					unless $?.exitstatus == 0
		        restart_failed_message += " QUEUE #{q_name} COULD NOT RESTART."
		        restart_failed = true
					end
					restart_msg += " QUEUE #{q_name} RESTARTED."
				end

			end

			if restart_failed
				return restart_failed_message
			else
				return restart_msg
			end

		end

	end

	def verify_security_token_get
  	unless params[:secret] == '64zNYufgM8dL1x506FY092uKbms23tT7'
  		render status: :forbidden, text: "You do not have access to this page."
  	end
  end

end