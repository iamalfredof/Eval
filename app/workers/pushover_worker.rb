class PushoverWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  sidekiq_options :queue => :default

  def perform(title, message)
    # Carlos' credentials
    Pushover.notification(
    	title: title,
      message: message,
      user: 'u4ignr2qcqsxray22nxjj792qfgras',
      token: 'a34roc2qfzdtzkm242g13wh5tc7ua9'
    )

    # Ricardo's credentials
    Pushover.notification(
      title: title,
      message: message,
      user: 'uj9g7pgk8njoam6866fwhn9c2e21vz',
      token: 'ayvak424nb9pqhsvvosxf5wswtht5y'
    )
  end
  
end