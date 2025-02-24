# frozen_string_literal: true

require 'rails_helper'
require 'bgs_service/local_bgs'

describe ClaimsApi::LocalBGS do
  subject { described_class.new external_uid: 'xUid', external_key: 'xKey' }

  describe '#find_poa_by_participant_id' do
    it 'responds as expected, with extra ClaimsApi::Logger logging' do
      VCR.use_cassette('bgs/claimant_web_service/find_poa_by_participant_id') do
        allow_any_instance_of(BGS::OrgWebService).to receive(:find_poa_history_by_ptcpnt_id).and_return({})

        # Events logged:
        # 1: establish_ssl_connection - how long to establish the connection
        # 2: connection_wsdl_get - duration of WSDL request cycle
        # 3: connection_post - how long does the post itself take for the request cycle
        # 4: parsed_response - how long to parse the response
        expect(ClaimsApi::Logger).to receive(:log).exactly(4).times
        result = subject.find_poa_by_participant_id('does-not-matter')
        expect(result).to be_a Hash
        expect(result[:end_date]).to eq '08/26/2020'
      end
    end

    it 'triggers StatsD measurements' do
      VCR.use_cassette('bgs/claimant_web_service/find_poa_by_participant_id', allow_playback_repeats: true) do
        allow_any_instance_of(BGS::OrgWebService).to receive(:find_poa_history_by_ptcpnt_id).and_return({})

        %w[establish_ssl_connection connection_wsdl_get connection_post parsed_response].each do |event|
          expect { subject.find_poa_by_participant_id('does-not-matter') }
            .to trigger_statsd_measure("api.claims_api.local_bgs.#{event}.duration")
        end
      end
    end
  end
end
