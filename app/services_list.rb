require 'json'
require 'httparty'

API_TOKEN = ENV['PAGERDUTY_TOKEN']
PD_SERV = "https://api.pagerduty.com/services?time_zone=UTC&sort_by=name%3Aasc&offset="


class Services
  def services_list()
    service_names = ["All Services"]
    responses = get_data()
    responses.each do |data|
      service_names += parse_service_names(data["services"])
    end
    service_names.uniq!
    return service_names.to_json
  end

  def get_data()
    data = []
    offset = 0
    more = true
    while more
      response = HTTParty.get(
        PD_SERV + offset.to_s,
        headers: {
          'Content-Type' => 'application/json',
          'Accept' => 'application/vnd.pagerduty+json;version=2',
          'Authorization' => "Token token=#{API_TOKEN}"
        }
      )
      parsed = JSON.parse(response.body)
      data << parsed
      more = parsed["more"]
      print more
      offset += 25
    end
    return data
  end

  def parse_service_names(services)
    service_names = []
    services.each do |list|
      begin
        new_str = list["name"].split(".")[0]
        service_names << new_str
      rescue
      end
    end
    service_names.delete("All")
    return service_names
  end
end
