# frozen_string_literal: true

module ClaimsApi
  ##
  # Class to interact with the BRD API
  #
  # Takes an optional request parameter
  # @param [] rails request object
  class BRD
    def initialize(request = nil)
      @request = request
    end

    ##
    # List of valid countries
    #
    # @return [Array<String>] list of countries
    def countries
      client.get('countries').body[:items]
    end

    def intake_sites
      client.get('intake-sites').body[:items]
    end

    private

    def client
      base_name = if !Settings.brd&.base_name.nil?
                    Settings.brd.base_name
                  elsif @request&.host_with_port.nil?
                    'api.va.gov/services'
                  else
                    "#{@request&.host_with_port}/services"
                  end

      api_key = Settings.brd&.api_key || ENV.fetch('BRD_API_KEY', '')
      raise StandardError, 'BRD api_key missing' if api_key.blank?

      Faraday.new("https://#{base_name}/benefits-reference-data/v1",
                  # Disable SSL for (localhost) testing
                  ssl: { verify: Settings.brd&.ssl != false },
                  headers: { 'apiKey' => api_key }) do |f|
        f.request :json
        f.response :raise_error
        f.response :json, parser_options: { symbolize_names: true }
        f.adapter Faraday.default_adapter
      end
    end
  end
end
