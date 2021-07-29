# frozen_string_literal: true

RSpec.describe Volcanic::Imageman::V1::Image do
  subject(:instance) do
    described_class.create \
      attachable: attachable,
      reference: reference,
      name: name,
      cacheable: cacheable,
      cache_duration: cache_duration
  end

  let(:attachable) { 'base64-string' }
  let(:reference) { 'reference' }
  let(:name) { 'name' }
  let(:cacheable) { nil }
  let(:cache_duration) { nil }
  let(:mock_uuid) { 'uuid' }

  let(:file) { Volcanic::Imageman::V1::Attachable }
  let(:conn) { Volcanic::Imageman::Connection }
  let(:response) { double 'response' }
  let(:api_path) {}
  let(:signed_url) {}
  let(:response_body) do
    {
      fileName: name,
      reference: reference,
      UUID: mock_uuid,
      signed_url: signed_url
    }
  end

  let(:image_error) { Volcanic::Imageman::ImageError }
  let(:server_error) { Volcanic::Imageman::ServerError }
  let(:duplicates_error) { Volcanic::Imageman::DuplicateImage }

  before do |test|
    allow(response).to receive(:body).and_return(response_body)
    if test.metadata[:using_signed_url]
      allow_any_instance_of(file).to receive(:size_at_base64).and_return(three_mb)
      allow_any_instance_of(conn).to receive(:post).with(api_path).and_return(response)
      allow_any_instance_of(conn).to receive(:post).with(signed_url[:url]).and_return(true)
    else
      allow_any_instance_of(conn).to receive(:get).with(anything).and_return(response)
      allow_any_instance_of(conn).to receive(:post).with(anything).and_return(response)
      allow_any_instance_of(conn).to receive(:delete).with(anything).and_return(response)
    end
  end

  describe 'create' do
    context 'with missing attachable' do
      let(:attachable) { nil }
      it('raises an exception') { expect { instance }.to raise_error(ArgumentError) }
    end

    context 'with missing reference' do
      let(:reference) { nil }
      it('raises an exception') { expect { subject }.to raise_error(ArgumentError) }
    end

    context 'with missing name' do
      let(:name) { nil }
      it('raises an exception') { expect { subject }.to raise_error(ArgumentError) }
    end

    context 'with reference as Volcanic::Imageman::V1::Reference' do
      let(:reference) { Volcanic::Imageman::V1::Reference.new(name: name, source: 'test-suite') }
      let(:response_body) { { reference: reference.md5_hash } }
      its(:reference) { should eq reference.md5_hash }
    end

    context 'with reference as String' do
      let(:reference) { '123' }
      let(:response_body) { { reference: reference } }
      its(:reference) { should eq reference }
    end

    # support only for +io+ key
    context 'with attachable as Hash ' do
      let(:attachable) { { io: Tempfile.new('test.jpeg') } }
      it('return an instance') { expect(subject).to be_an_instance_of(described_class) }
    end

    # Readable type such as:
    # +ActionDispatch::Http::UploadedFile+, +Rack::Test::UploadedFile+, +Tempfile+
    context 'with attachable as readable type ' do
      let(:attachable) { Tempfile.new('test.jpeg') }
      it('return an instance') { expect(subject).to be_an_instance_of(described_class) }
    end

    context 'with attachable as string base64 ' do
      let(:attachable) { 'base64_string' }
      it('return an instance') { expect(subject).to be_an_instance_of(described_class) }
    end

    context 'should get latest version' do
      let(:response_body) { { version: 1 } }
      its(:version) { should eq 1 }
    end

    context 'when return with versions details' do
      let(:mock_versions) { { id: 1, version_id: 1, s3_key: 's3key' } }
      let(:response_body) { { versions: [mock_versions] } }
      its(:versions) { should be_an_instance_of Array }
      it { expect(instance.versions.first).to be_an_instance_of Volcanic::Imageman::V1::Version }
      it { expect(instance.versions.first.id).to eq 1 }
      it { expect(instance.versions.first.version_id).to eq 1 }
      it { expect(instance.versions.first.s3_key).to eq 's3key' }
    end

    context 'when failed request of validation error (400)' do
      before { allow_any_instance_of(conn).to receive(:post).with(anything).and_raise(image_error) }
      it('raises an exception') { expect { subject }.to raise_error image_error }
    end

    context 'when failed request of Duplicates error (400)' do
      before { allow_any_instance_of(conn).to receive(:post).with(anything).and_raise(duplicates_error) }
      it('raises an exception') { expect { subject }.to raise_error duplicates_error }
    end

    context 'when failed request of validation error (500)' do
      before { allow_any_instance_of(conn).to receive(:post).with(anything).and_raise(server_error) }
      it('raises an exception') { expect { subject }.to raise_error server_error }
    end

    context 'when image exceed limit', :using_signed_url do
      let(:api_path) { '/api/v1/images' }
      let(:signed_url) { { url: 'http://s3-signed-url', fields: { some_keys: '1234' } } }

      it('return an instance') { expect(subject).to be_an_instance_of(described_class) }
    end
  end

  describe 'fetch_by' do
    subject { described_class.fetch_by(attr) }

    context 'missing reference or uuid' do
      let(:attr) { nil }
      it('raises an exception') { expect { subject }.to raise_error(ArgumentError) }
    end

    context 'reference' do
      let(:attr) { { reference: reference } }
      its(:name) { should eq name }
      its(:reference) { should eq reference }
      its(:uuid) { should eq mock_uuid }
    end

    context 'uuid' do
      let(:attr) { { uuid: mock_uuid } }
      its(:name) { should eq name }
      its(:reference) { should eq reference }
      its(:uuid) { should eq mock_uuid }
    end
  end

  describe '#reload' do
    subject { instance.reload }

    context 'when missing both uuid and reference (not persisted)' do
      let(:instance) { described_class.new }
      it('return false') { is_expected.to be false }
    end

    context 'when exists of reference' do
      let(:instance) { described_class.new(reference: reference) }
      it('return true') { is_expected.to be true }
    end

    context 'when exists of uuid' do
      let(:instance) { described_class.new(uuid: mock_uuid) }
      it('return true') { is_expected.to be true }
    end

    context 'if persisted' do
      let(:instance) { described_class.new(reference: reference) }
      before { instance.reload }
      subject { instance }
      its(:name) { should eq name }
      its(:uuid) { should eq mock_uuid }
    end
  end

  describe '#delete' do
    subject { instance.delete }
    context 'when missing both uuid and reference (not persisted)' do
      let(:instance) { described_class.new }
      it('return false') { is_expected.to be false }
    end

    context 'if persisted' do
      let(:instance) { described_class.new(uuid: mock_uuid) }
      it('return true') { is_expected.to be true }
    end
  end

  describe '#update' do
    let(:base64_string) { attachable }
    subject { instance.update(base64_string) }

    context 'when missing both uuid and reference (not persisted)' do
      let(:instance) { described_class.new }
      it('return false') { is_expected.to be false }
    end

    context 'if persisted' do
      let(:instance) { described_class.new(uuid: mock_uuid) }
      it('return true') { is_expected.to be true }
    end

    context 'when image exceed limit', :using_signed_url do
      let(:instance) { described_class.new(uuid: mock_uuid) }
      let(:api_path) { '/api/v1/images/uuid' }
      let(:signed_url) { { url: 'http://s3-signed-url', fields: { some_keys: '1234' } } }
      it('return true') { is_expected.to be true }
    end
  end

  private

  def three_mb
    3 * 1024 * 1024
  end
end
