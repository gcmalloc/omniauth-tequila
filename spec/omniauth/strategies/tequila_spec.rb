require 'spec_helper'

describe OmniAuth::Strategies::Tequila, type: :strategy do
  include Rack::Test::Methods

  class MyTequilaProvider < OmniAuth::Strategies::Tequila; end # TODO: Not really needed. just an alias but it requires the :name option which might confuse users...
  def app
    Rack::Builder.new {
      use OmniAuth::Test::PhonySession
      use MyTequilaProvider, name: :tequila, host: 'tequila.example.org', path: '/application/path', ssl: false, port: 8080, uid_field: :specuid,
        request_info: { :name => 'displayname', :first_name => 'firstname', :last_name => 'name', :email => 'email', :phone => 'phone' }
      run lambda { |env| [404, {'Content-Type' => 'text/plain'}, [env.key?('omniauth.auth').to_s]] }
    }.to_app
  end

  describe 'default options' do
    subject { MyTequilaProvider.default_options.to_hash }
    it 'points to the EPFL server over SSL' do
      should include('ssl' => true)
      should include('host' => 'tequila.epfl.ch')
      should include('require_group' => nil)
      should include('service_name' => 'Omniauth')
      should include('port' => nil)
      should include('path' => '/cgi-bin/tequila')
      should include('uid_field' => :uniqueid)
    end
  end

  describe 'GET /auth/tequila' do
    # setup mock Tequila createrequest response
    before(:each) do
      stub_request(:post, 'http://tequila.example.org:8080/application/path/createrequest')
        .with { |request| @request_body = request.body }
        .to_return( status: response_code, body: response_body )
      get '/auth/tequila'
    end

    shared_examples 'Tequila createrequest' do
      describe 'createrequest body' do
        subject { @request_body }
        it { should match( /^urlaccess=http:\/\/example.org\/auth\/tequila\/callback$/ ) }
        it { should match( /^service=Omniauth$/ ) }

        describe 'requested attributes' do
          subject { @request_body[/^request=(.*)$/, 1].scan( /(\w+)(,|$)/ ).collect(&:first) }
          it { should have(6).items }
          it { should include('specuid') }
          it { should include('displayname') }
          it { should include('email') }
          it { should include('firstname') }
          it { should include('name') }
          it { should include('phone') }
        end
      end
    end

    context 'when Tequila server works' do
      let(:response_code) { 200 }
      let(:response_body) { 'key=shkfe31zsy3ow7sgnfv2e2q164cbf1to' }
      it_behaves_like 'Tequila createrequest'

      subject { last_response }
      it { should be_redirect }
      it 'should redirect to the Tequila server' do
        subject.headers['Location'].should == 'http://tequila.example.org:8080/application/path/requestauth?' +
          'requestkey=shkfe31zsy3ow7sgnfv2e2q164cbf1to'
      end
    end

    context 'when Tequila server returns a bad reponse code' do
      let(:response_code) { 404 }
      let(:response_body) { 'Page not found' }
      it_behaves_like 'Tequila createrequest'

      subject { last_response }
      it { should be_redirect }
      it 'should fail with invalid_response' do
        subject.headers['Location'].should == '/auth/failure?message=invalid_response&strategy=tequila'
      end
    end

    context 'when Tequila server returns a bad response body' do
      let(:response_code) { 200 }
      let(:response_body) { 'brokenkey=shkfe31zsy3ow7sgnfv2e2q164cbf1to' }
      it_behaves_like 'Tequila createrequest'

      subject { last_response }
      it { should be_redirect }
      it 'should fail with invalid_key' do
        subject.headers['Location'].should == '/auth/failure?message=invalid_key&strategy=tequila'
      end
    end
  end

  describe 'GET /auth/tequila/callback' do
    # setup mock Tequila fetchattributes response
    before(:each) do
      stub_request(:post, 'http://tequila.example.org:8080/application/path/fetchattributes')
        .with { |request| @request_body = request.body }
        .to_return( status: response_code, body: response_body )
      get '/auth/tequila/callback?key=esu3r5e6fy0c616af80y5ienzrj2n6x8'
    end

    shared_examples 'Tequila fetchattributes' do
      describe 'fetchattributes body' do
        subject { @request_body }
        it { should match( /^key=esu3r5e6fy0c616af80y5ienzrj2n6x8$/ ) }
      end
    end

    context 'when Tequila server works' do
      let(:response_code) { 200 }
      let(:response_body) { File.read('spec/fixtures/tequila_fetchattributes_good.txt') }
      it_behaves_like 'Tequila fetchattributes'

      describe 'omniauth.auth' do
        subject { last_request.env['omniauth.auth'] }
        it { should be_kind_of Hash }
        its(:provider) { should == :tequila }
        its(:uid) { should == '999999' }
      end

      describe 'omniauth.auth.info' do
        subject { last_request.env['omniauth.auth']['info'] }
        it { should have(5).items }
        its(:name)       { should == 'Chris Bird' }
        its(:first_name) { should == 'Chris' }
        its(:last_name)  { should == 'Bird' }
        its(:email)      { should == 'chris@twowordbird.com' }
        its(:phone)      { should == '+41 21 9999999' }
      end

      describe 'omniauth.auth.extra' do
        subject { last_request.env['omniauth.auth']['extra'] }
        it { should have(11).items }
        its(:version)      { should == '2.1.2' }
        its(:provider)     { should == '' }
        its(:specrequire)  { should == 'group=my-group' }
        its(:status)       { should == 'ok' }
        its(:speckey)      { should == 'esu3r5e6fy0c616af80y5ienzrj2n6x8' }
        its(:group)        { should == 'my-group' }
        its(:requesthost)  { should == '128.128.128.128' }
        its(:authstrength) { should == '1' }
        its(:org)          { should == 'MYORG' }
        its(:host)         { should == '128.128.128.129' }
        its(:authorig)     { should == 'cookie' }
      end
    end

    context 'when Tequila server returns a bad response code' do
      let(:response_code) { 404 }
      let(:response_body) { 'Page not found' }
      it_behaves_like 'Tequila fetchattributes'

      subject { last_response }
      it { should be_redirect }
      it 'should fail with invalid_response' do
        subject.headers['Location'].should == '/auth/failure?message=invalid_response&strategy=tequila'
      end
    end

    context 'when Tequila server returns bad info' do
      let(:response_code) { 200 }
      let(:response_body) { File.read('spec/fixtures/tequila_fetchattributes_bad.txt') }
      it_behaves_like 'Tequila fetchattributes'

      subject { last_response }
      it { should be_redirect }
      it 'should fail with invalid_info' do
        subject.headers['Location'].should == '/auth/failure?message=invalid_info&strategy=tequila'
      end
    end
  end

end
