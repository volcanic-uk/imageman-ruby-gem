# frozen_string_literal: true

RSpec.describe Volcanic::Imageman::Connection do
  let(:stubs)  { Faraday::Adapter::Test::Stubs.new }
  let(:middleware) {}
  let(:base_url) { Volcanic::Imageman.configure.domain_url }
  let(:conn) do
    Faraday.new(base_url) do |connection|
      connection.adapter(:test, stubs)
      connection.use middleware
    end
  end

  let(:status) { 200 }
  let(:headers) { { 'Content-Type' => 'application/json' } }
  let(:body) { { foo: 'bar' } }
  let(:response) { [status, headers, body.to_json] }

  subject do
    stubs.get('/foobar') do |env|
      expect(env.url.path).to eq('/foobar')
      response
    end
    conn.get('/foobar')
  end

  describe 'when using User-Agent middleware' do
    let(:middleware) { Volcanic::Imageman::Middleware::UserAgent }
    it('should content User-Agent header') do
      expect(subject.env[:request_headers]).to eq({ 'User-Agent' => 'Imageman v0.1.0' })
    end
  end

  describe 'when using RequestId middleware' do
    let(:middleware) { Volcanic::Imageman::Middleware::RequestId }
    it('should content x-request-id header') do
      expect(subject.env[:request_headers]['x-request-id']).to be_present
    end
  end

  describe 'when using Authentication middleware' do
    let(:middleware) { Volcanic::Imageman::Middleware::Authentication }

    it('should content Authorization header') do
      expect(subject.env[:request_headers]['Authorization']).to be_present
    end

    context 'processing auth key' do
      let(:auth_key) {}
      before { Volcanic::Imageman.configure.authentication = auth_key }

      context 'when auth_key is a string' do
        let(:auth_key) { '1234' }
        it { expect(subject.env[:request_headers]['Authorization']).to eq 'Bearer 1234' }
      end

      context 'when auth_key is a type of callable' do
        let(:auth_key) { -> { '1234' } }
        it { expect(subject.env[:request_headers]['Authorization']).to eq 'Bearer 1234' }
      end
    end

    context 'when requesting to non-imageman url' do
      let(:base_url) { 'http://not-imageman-url' }
      it 'should not content Authorization header' do
        expect(subject.env[:request_headers]['Authorization']).to be_nil
      end
    end
  end

  describe 'when using Exception middleware' do
    let(:middleware) { Volcanic::Imageman::Middleware::Exception }

    context 'when response status 400' do
      let(:status) { 400 }
      let(:body) { { errorCode: 1001 } }
      it('raises ImageError') { expect { subject }.to raise_error Volcanic::Imageman::ImageError }
    end

    context 'when response status 400 and Duplicates (1002)' do
      let(:status) { 400 }
      let(:body) { { errorCode: 1002 } }
      it('raises DuplicateImage') { expect { subject }.to raise_error Volcanic::Imageman::DuplicateImage }
    end

    context 'when response status 400 and FileNotSupported (1003)' do
      let(:status) { 400 }
      let(:body) { { errorCode: 1003 } }
      it('raises FileNotSupported') { expect { subject }.to raise_error Volcanic::Imageman::FileNotSupported }
    end

    context 'when response status 403 forbidden' do
      let(:status) { 403 }
      it('raises Forbidden') { expect { subject }.to raise_error Volcanic::Imageman::Forbidden }
    end

    context 'when response status 404 NotFound' do
      let(:status) { 404 }
      it('raises ImageNotFound') { expect { subject }.to raise_error Volcanic::Imageman::ImageNotFound }
    end

    context 'when response status 404 from s3 signed url' do
      let(:base_url) { 'http://s3-signed-url' }
      let(:status) { 400 }
      it('raises S3SignedUrlError') { expect { subject }.to raise_error Volcanic::Imageman::S3SignedUrlError }
    end
  end
end
