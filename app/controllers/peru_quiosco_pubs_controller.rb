class PeruQuioscoPubsController < ApplicationController

	def index
		@pubs = PeruQuioscoPub.all
	end

end