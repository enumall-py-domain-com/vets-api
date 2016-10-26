# frozen_string_literal: true
require 'savon'
require_relative 'responses/find_candidate'

module MVI
  # Wrapper for the MVI (Master Veteran Index) Service. vets.gov has access
  # to three MVI endpoints:
  # * prpa_in201301_uv02 (TODO(AJD): Add Person)
  # * prpa_in201302_uv02 (TODO(AJD): Update Person)
  # * prpa_in201305_uv02 (aliased as .find_candidate)
  #
  # = Usage
  # Calls endpoints as class methods, if successful it will return a ruby hash of the SOAP XML response.
  #
  # Example:
  #  birth_date = Time.new(1980, 1, 1).utc
  #  message = MVI::Messages::FindCandidateMessage.new(['John', 'William'], 'Smith', birth_date, '555-44-3333').to_xml
  #  response = MVI::Service.find_candidate(message)
  #
  class Service
    extend Savon::Model

    def self.options
      opts = {
        wsdl: @wsdl ||= ERB.new(File.read('config/mvi_schema/IdmWebService_200VGOV.wsdl.erb')).result
      }
      if ENV['MVI_CLIENT_CERT_PATH'] && ENV['MVI_CLIENT_KEY_PATH']
        opts[:ssl_cert_file] = ENV['MVI_CLIENT_CERT_PATH']
        opts[:ssl_cert_key_file] = ENV['MVI_CLIENT_KEY_PATH']
      end
      opts
    end

    client options
    operations :prpa_in201301_uv02, :prpa_in201302_uv02, :prpa_in201305_uv02

    def self.prpa_in201305_uv02(message)
      response = MVI::Responses::FindCandidate.new(super(xml: message.to_xml))
      invalid_request_handler('find_candidate', response.body) if response.invalid?
      request_failure_handler('find_candidate', response.body) if response.failure?
      raise MVI::RecordNotFound.new('MVI subject missing from response body', response) unless response.body
      response.body
    rescue Savon::SOAPFault => e
      # TODO(AJD): cloud watch metric for error code
      Rails.logger.error "mvi find_candidate soap error code: #{e.http.code} message: #{e.message}"
      raise MVI::SOAPError, e.message
    rescue Savon::HTTPError => e
      # TODO(AJD): cloud watch metric for error code
      Rails.logger.error "mvi find_candidate http error code: #{e.http.code} message: #{e.message}"
      raise MVI::HTTPError, e.message
    rescue SocketError => e
      Rails.logger.error "mvi find_candidate socket error: #{e.message}"
      message = 'mvi requires a vpn connection, or use the mock mvi service as detailed in the project README'
      raise MVI::ServiceError, message
    end

    singleton_class.send(:alias_method, :find_candidate, :prpa_in201305_uv02)

    def self.invalid_request_handler(operation, body)
      Rails.logger.error "mvi #{operation} invalid request structure: #{body}"
      raise MVI::InvalidRequestError
    end

    def self.request_failure_handler(operation, body)
      Rails.logger.error "mvi #{operation} request failure: #{body}"
      raise MVI::RequestFailureError
    end
  end
  class ServiceError < StandardError
  end
  class RequestFailureError < MVI::ServiceError
  end
  class InvalidRequestError < MVI::ServiceError
  end
  class SOAPError < MVI::ServiceError
  end
  class HTTPError < MVI::ServiceError
  end
  class RecordNotFound < StandardError
    attr_accessor :query, :original_response
    def initialize(message = nil, response = nil)
      super(message)
      @query = response.query
      @original_response = response.original_response
    end
  end
end
