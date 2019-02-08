require 'httparty'
require 'json'

PDALERT = "https://api.pagerduty.com/incidents?urgencies%5B%5D=high&time_zone=UTC"

class Query

attr_reader :output

  def initialize(request)
  # Fetch the service value selected on grafana
    req = JSON.parse(request.body.read)
    service_name = req["targets"][0]["target"]
    @cut_service_name = service_name.split(".")[0]
    type = req["targets"][0]["type"]

    if service_name.include?('.ack')
      @status = "&statuses%5B%5D=acknowledged"
    elsif service_name.include?('.tri')
      @status = "&statuses%5B%5D=triggered"
    else
      @status = "&statuses%5B%5D=triggered&statuses%5B%5D=acknowledged"
    end

    if type == "timeserie"
      metric()
    else
      table()
    end
  end

  def call()
    url = PDALERT + @status
# request to PD to get current active alerts
    response = HTTParty.get(
      url,
      headers: {
        'Content-Type' => 'application/json',
        'Accept' => 'application/vnd.pagerduty+json;version=2',
        'Authorization' => "Token token=#{API_TOKEN}"
      }
    )
    return JSON.parse(response.body)
  end


  def parse_incidents_stat()
    result = []
    parsed = call()
# add to array key incident data: Service, Incident Title, Urgency and current status
    parsed["incidents"].each do |list|
      date = DateTime.parse(list["created_at"])
      incident = [
        list["service"]["summary"],
        list["title"],
        list["urgency"],
        date.strftime("%d/%m/%Y %H:%M"),
        list["status"],
        list["assignments"][0]["assignee"]["summary"]
      ]
# If service selected in grafana matches a current alert, add alert to result array
      if list["service"]["summary"].include? @cut_service_name
        result << incident
# If All Services is selected in grafana add alert to result array
      elsif @cut_service_name.include? "All Services"
        result << incident
      end
    end
    return result
  end

  def table()
# Format result into grafana table format
  incident = parse_incidents_stat()
    tab = [
      {
        "columns" => [
          {"text" => "Service","type" => "string"},
          {"text" => "Title","type" => "string"},
          {"text" => "Urgency","type" => "string"},
          {"text" => "Start Time","type" => "string"},
          {"text" => "Status","type" => "string"},
          {"text" => "Assignee","type" => "string"}
        ],
        "rows" => incident,
        "type" => "table"
      }
    ]
    @output = tab.to_json
    return tab.to_json
  end

  def metric()
  # Output count of incidents for grafana metric
  incident = parse_incidents_stat()
    met =  [
      {
        "target"=> @cut_service_name,
        "datapoints"=> [
          [incident.count,1450754160000]
        ]
      }
    ]
    @output = met.to_json
    return met.to_json
  end

end
