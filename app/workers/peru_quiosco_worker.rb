class PeruQuioscoWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  sidekiq_options :queue => :default

  def perform(product)
    PeruQuioscoPub.new.schedule_pq(product)
    
    # This URL will always get the latest daily publication
    latest_pub_url          = "http://visor.quioscodigital.pe/servicioauth/ws/" + product + ".json" # elcomercio, gestion, peru21, trome, depor, correo
    pub                     = JSON.parse( HTTParty.get(latest_pub_url).body )
    pub_pages               = pub['pages']
    pq_firstpage_id         = Integer( pub_pages[0]['id'] )
    pub_time                = Time.at( pub['pubtime'] ).to_s(:db)
    product                 = pub['name']
    title                   = product + " " + DateTime.strptime(pub['pubtime'].to_s,'%s').strftime("[%d/%m/%Y]")

    PeruQuioscoPub.create(:pq_firstpage_id => pq_firstpage_id,
                          :pub_size => pub_pages.size,
                          :title => title,
                          :pub_time => pub_time,
                          :product => product)
    Rails.logger.info "Creating: " + title]
  end
  
end