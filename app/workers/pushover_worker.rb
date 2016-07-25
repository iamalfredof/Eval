class PushoverWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  sidekiq_options :queue => :default

  def perform(title, message)
    # Carlos' credentials are being used
    Pushover.notification(
    	title: title,
      message: message,
      user: 'u4ignr2qcqsxray22nxjj792qfgras',
      token: 'a34roc2qfzdtzkm242g13wh5tc7ua9'
    )
  end
  
end