# frozen_string_literal: true

require 'rails_helper'
require 'vba_documents/document_request_validator'
require_relative '../support/vba_document_fixtures'

RSpec.describe VBADocuments::DocumentRequestValidator do
  include VBADocuments::Fixtures

  describe '#validate' do
    let(:fixture_name) { 'valid_doc.pdf' }
    let(:headers) { { 'Content-Type' => 'application/pdf' } }
    let(:request) { instance_double(ActionDispatch::Request) }
    let(:result) { described_class.new(request).validate }

    before do
      allow(request).to receive(:body).and_return(get_fixture(fixture_name))
      allow(request).to receive(:headers).and_return(headers)
    end

    it 'considers a valid PDF valid' do
      expect(result.dig(:data, :attributes, :status)).to eq('valid')
    end

    describe 'given a document with large pages' do
      let(:fixture_name) { '18x22.pdf' }

      context 'when vba_documents_larger_page_size_limit flag is off' do
        before { Flipper.disable(:vba_documents_larger_page_size_limit) }

        describe 'with large PDF' do
          it 'errors' do
            expect(result[:errors].length).to eq(1)
            expect(result[:errors].first[:status]).to eq('422')
          end
        end

        describe 'with extra large PDF' do
          let(:fixture_name) { '10x102.pdf' }

          it 'errors' do
            expect(result[:errors].length).to eq(1)
            expect(result[:errors].first[:status]).to eq('422')
          end
        end
      end

      context 'when vba_documents_larger_page_size_limit flag is on' do
        before { Flipper.enable(:vba_documents_larger_page_size_limit) }

        describe 'with large PDF' do
          it 'considers the PDF valid' do
            expect(result.dig(:data, :attributes, :status)).to eq('valid')
          end
        end

        describe 'with extra large PDF' do
          let(:fixture_name) { '10x102.pdf' }

          it 'errors' do
            expect(result[:errors].length).to eq(1)
            expect(result[:errors].first[:status]).to eq('422')
          end
        end
      end
    end

    describe 'given a PDF with an owner/permissions password' do
      let(:fixture_name) { 'encrypted.pdf' }

      it 'considers the PDF valid' do
        expect(result.dig(:data, :attributes, :status)).to eq('valid')
      end
    end

    describe 'given a PDF with a user password' do
      let(:fixture_name) { 'locked.pdf' }

      it 'considers the PDF invalid' do
        errors = result[:errors]
        expect(errors.length).to eq(1)
        expect(errors.first[:status]).to eq('422')
      end
    end
  end
end
