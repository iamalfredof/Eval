 module ApiHelper
   
  def udocz_url
   #"https://www.udocz.com"
   "https://udocz-staging.herokuapp.com"
  end
  
  def html_callback(_action, log_info, html_url, document_id)
    response = HTTParty.get( udocz_url + '/api/v1/' + _action + '/' + document_id.to_s + '.json', 
              :verify   => false,
              :body     => { :url => html_url }.to_json,
              :headers  => { 'Content-Type' => 'application/json' } )
    Rails.logger.info log_info
    Rails.logger.info get_html_url
    response
  end
  
 end