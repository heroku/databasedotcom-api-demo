require 'omniauth/strategies/salesforce'

module OmniAuth
  module Strategies
    class Salesforce < OmniAuth::Strategies::OAuth2
      def initialize(app, consumer_key = nil, consumer_secret = nil, options = {}, &block)
        client_options = {
          :site => 'https://vmf02.t.salesforce.com',
          :authorize_path => '/services/oauth2/authorize',
          :access_token_path => '/services/oauth2/token'
        }

        options.merge!(:response_type => 'code', :grant_type => 'authorization_code')

        super(app, :salesforce, consumer_key, consumer_secret, client_options, options, &block)
      end
    end
  end
end
