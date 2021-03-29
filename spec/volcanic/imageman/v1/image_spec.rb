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

  before do
    allow(response).to receive(:body).and_return(response_body)
    allow_any_instance_of(conn).to receive(:get).with(anything).and_return(response)
    allow_any_instance_of(conn).to receive(:post).with(anything).and_return(response)
    allow_any_instance_of(conn).to receive(:delete).with(anything).and_return(response)
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

    context 'when image exceed limit' do
      let(:signed_url) { 'http://s3-signed-url' }
      before do
        allow_any_instance_of(file).to receive(:size_at_base64).and_return(six_mb)
        allow_any_instance_of(conn).to receive(:put).with(signed_url).and_return(true)
      end

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
    subject { instance.update(attachable: base64_string) }

    context 'when missing both uuid and reference (not persisted)' do
      let(:instance) { described_class.new }
      it('return false') { is_expected.to be false }
    end

    context 'if persisted' do
      let(:instance) { described_class.new(uuid: mock_uuid) }
      it('return true') { is_expected.to be true }
    end

    context 'when image exceed limit' do
      let(:signed_url) { 'http://s3-signed-url' }
      before do
        allow_any_instance_of(file).to receive(:size_at_base64).and_return(six_mb)
        allow_any_instance_of(conn).to receive(:put).with(signed_url).and_return(true)
      end

      it('return true') { is_expected.to be true }
    end
  end

  private

  def six_mb
    6 * 1024 * 1024
  end
end
