require 'omniauth/strategy'
require 'addressable/uri'
require 'net/http'

module OmniAuth
  module Strategies
    class Tequila
      include OmniAuth::Strategy

      class TequilaFail < StandardError; end

      attr_accessor :raw_info
      alias_method :user_info, :raw_info

      option :name, :tequila # Required property by OmniAuth::Strategy

      option :host, 'tequila.epfl.ch'
      option :require_group, nil
      option :service_name, 'Omniauth'
      option :port, nil
      option :path, '/cgi-bin/tequila'
      option :ssl, true
      option :uid_field, :uniqueid
      option :request_info, { :name => 'displayname' }
      option :additional_parameters, {}

      # As required by https://github.com/intridea/omniauth/wiki/Auth-Hash-Schema
      info do
        Hash[ @options[:request_info].map {|k, v| [ k, raw_info[v] ] } ]
      end

      extra do
        raw_info.reject {|k, v| k == @options[:uid_field].to_s or @options[:request_info].values.include?(k) }
      end

      uid do
        raw_info[ @options[:uid_field].to_s ]
      end

      def callback_phase
        response = fetch_attributes( request.params['key'] )

        return fail!(:invalid_response, TequilaFail.new('nil response from Tequila')) if response.nil?
        return fail!(:invalid_response, TequilaFail.new('Invalid reponse from Tequila: ' + response.code)) unless response.code == '200'

        # parse attributes
        self.raw_info = {}
        response.body.each_line { |line|
          item = line.split('=', 2)
          if item.length == 2
            raw_info[item[0]] = item[1].strip
          end
        }

        missing_info = @options[:request_info].values.reject { |k| raw_info.include?(k) }
        if !missing_info.empty?
          log :error, 'Missing attributes in Tequila server response: ' + missing_info.join(', ')
          return fail!(:invalid_info, TequilaFail.new('Invalid info from Tequila'))
        end

        super
      end

      def request_phase
        response = get_request_key
        if response.nil? or response.code != '200'
          log :error, 'Received invalid response from Tequila server: ' + (response.nil? ? 'nil' : response.code)
          return fail!(:invalid_response, TequilaFail.new('Invalid response from Tequila server'))
        end

        request_key = response.body[/^key=(.*)$/, 1]
        if request_key.nil? or request_key.empty?
          log :error, 'Received invalid key from Tequila server: ' + (request_key.nil? ? 'nil' : request_key)
          return fail!(:invalid_key, TequilaFail.new('Invalid key from Tequila'))
        end

        # redirect to the Tequila server's login page
        [
          302,
          {
            'Location' => tequila_uri.to_s + '/requestauth?requestkey=' + request_key,
            'Content-Type' => 'text/plain'
          },
          ['You are being redirected to Tequila for sign-in.']
        ]
      end

    private

      # retrieves user attributes from the Tequila server
      def fetch_attributes( request_key )
        tequila_post '/fetchattributes', "key=" + request_key
      end

      # retrieves the request key from the Tequila server
      def get_request_key
        # NB: You might want to set the service and required group yourself.
        request_fields = @options[:request_info].values << @options[:uid_field]
        body = 'urlaccess=' + callback_url + "\nservice=" + @options[:service_name] + "\n" +
          'request=' + request_fields.join(',')
        if @options[:require_group]
          body += "\nrequire=group=" + @options[:require_group]
        end

        @options[:additional_parameters].each { |param, value| body += "\n" + param + "=" + value}
        
        tequila_post '/createrequest', body
      end

      # Build a Tequila host with protocol and port
      #
      #
      def tequila_uri
        @tequila_uri ||= begin
          if @options.port.nil?
            @options.port = @options.ssl ? 443 : 80
          end
          Addressable::URI.new(
            :scheme => @options.ssl ? 'https' : 'http',
            :host   => @options.host,
            :port   => @options.port,
            :path   => @options.path
          )
        end
      end

      def tequila_post( path, body )
        http = Net::HTTP.new(tequila_uri.host, tequila_uri.port)
        http.use_ssl = @options.ssl
        if http.use_ssl?
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE if @options.disable_ssl_verification?
          http.ca_path = @options.ca_path
        end
        response = nil
        http.start do |c|
          response = c.request_post tequila_uri.path + path, body
        end
        response
      end

    end
  end
end
