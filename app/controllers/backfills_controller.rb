class BackfillsController < ApplicationController

	def index
		BackfillWorker.perform_async
	end

end