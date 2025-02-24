# frozen_string_literal: true

FactoryBot.define do
  factory :client_config, class: 'SignIn::ClientConfig' do
    client_id { SecureRandom.hex }
    authentication { SignIn::Constants::Auth::API }
    anti_csrf { false }
    redirect_uri { Faker::Internet.url }
    logout_redirect_uri { Faker::Internet.url }
    access_token_duration { SignIn::Constants::AccessToken::VALIDITY_LENGTH_SHORT_MINUTES }
    access_token_audience { SecureRandom.hex }
    refresh_token_duration { SignIn::Constants::RefreshToken::VALIDITY_LENGTH_SHORT_MINUTES }
  end
end
