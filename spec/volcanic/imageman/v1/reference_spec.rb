# frozen_string_literal: true

RSpec.describe Volcanic::Imageman::V1::Reference do
  subject(:instance) { described_class.new(**attrs) }
  let(:mock_name) { 'random-name' }
  let(:mock_source) { 'random-source' }
  let(:mock_opts) { { other_opts: 'some other value' } }
  let(:attrs) do
    {
      name: mock_name,
      source: mock_source,
      **mock_opts
    }
  end

  its(:name) { should eq mock_name }
  its(:source) { should eq mock_source }
  its(:opts) { should eq mock_opts }
  its(:md5_hash) { should eq build(mock_name, mock_source, mock_opts) }
  its(:url) { should eq build_url(mock_name, mock_source, mock_opts) }

  describe 'hash' do
    subject { described_class.hash(attrs) }
    it { is_expected.to eq build(mock_name, mock_source, mock_opts) }
  end

  describe 'hash_with_url' do
    subject { described_class.hash_with_url(attrs) }
    it { is_expected.to eq build_url(mock_name, mock_source, mock_opts) }
  end

  def build(name, source, opts)
    args = { name: name, source: source, service: Volcanic::Imageman.configure.service, **opts }.compact
    sort_keys_return_values = args.sort.to_h.values
    Digest::MD5.hexdigest(sort_keys_return_values.join(':'))
  end

  def build_url(name, source, opts)
    hash = build(name, source, opts)
    "#{Volcanic::Imageman.configure.asset_image_url}/#{hash}"
  end
end
