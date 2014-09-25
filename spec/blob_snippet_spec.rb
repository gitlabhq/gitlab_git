# encoding: UTF-8

require "spec_helper"

describe Gitlab::Git::BlobSnippet do
  describe :data do
    context 'empty lines' do
      let(:snippet) { Gitlab::Git::BlobSnippet.new('master', nil, nil, nil) }

      it { snippet.data.should be_nil }
    end

    context 'present lines' do
      let(:snippet) { Gitlab::Git::BlobSnippet.new('master', ['wow', 'much'], 1, 'wow.rb') }

      it { snippet.data.should == "wow\nmuch" }
    end
  end
end
