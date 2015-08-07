# OmniAuth Tequila Strategy [![Gem Version][version_badge]][version] [![Build Status][travis_status]][travis]

[version_badge]: https://badge.fury.io/rb/omniauth-tequila.png
[version]: http://badge.fury.io/rb/omniauth-tequila
[travis]: http://travis-ci.org/twowordbird/omniauth-tequila
[travis_status]: https://secure.travis-ci.org/twowordbird/omniauth-tequila.png

This is an OmniAuth 1.0 compatible strategy that authenticates via EPFL's [Tequila][tequila] protocol, structured after [omniauth-cas][omniauth_cas]. By default, it connects to EPFL's Tequila server, but it is fully configurable.

## Installation

Add this line to your application's Gemfile:

    gem 'omniauth-tequila'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install omniauth-tequila

## Usage

Use like any other OmniAuth strategy:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :tequila #, :option => value, ...
end
```

### Configuration Options

OmniAuth Tequila authenticates with the EPFL server over SSL by default. However, it supports the following configuration options:

  * `host` - Defines the host of your Tequila server
  * `require_group` - Defines the group that will have access to the service
  * `service_name` - Define the name the service will authenticate with to tequila
  * `path` - Defines the URL relative to the host that the application sits behind
  * `port` - The port to use for your configured Tequila `host`
  * `ssl` - true to connect to your Tequila server over SSL
  * `disable_ssl_verification` - Optional when `ssl` is true. Disables verification.
  * `ca_path` - Optional when `ssl` is `true`. Sets path of a CA certification directory. See [Net::HTTP][net_http] for more details
  * `uid_field` - The user data attribute to use as your user's unique identifier. Defaults to `'uniqueid'` (which contains the user's SCIPER number when using EPFL's Tequila server)
  * `request_info` - Hash that maps user attributes from Tequila to the [OmniAuth schema][omniauth_schema]. Defaults to `{ :name => 'displayname' }` (which is the user's full name when using EPFL's Tequila server)

If you encounter problems wih SSL certificates you may want to set the `ca_path` parameter or activate `disable_ssl_verification` (not recommended).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Thanks

Special thanks go out to the following people

  * Derek Lindahl (@dlindahl) and all the authors of [omniauth-cas][omniauth_cas]

[tequila]: http://tequila.epfl.ch/
[omniauth_cas]: http://github.com/dlindahl/omniauth-cas
[omniauth_schema]: https://github.com/intridea/omniauth/wiki/Auth-Hash-Schema
[net_http]: http://ruby-doc.org/stdlib-1.9.3/libdoc/net/http/rdoc/Net/HTTP.html
