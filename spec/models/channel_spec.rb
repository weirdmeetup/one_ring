require 'rails_helper'
require 'slack_client'

describe Channel, type: :model do
  describe '.init_with' do
    let(:api_client) { double('SlackApiClient') }
    let(:bot_client) { double('SlackBotClient') }

    before do
      allow(SlackClient).to receive(:build_api_client).and_return(api_client)
      allow(SlackClient).to receive(:build_bot_client).and_return(bot_client)
      ch = double(id: 'cid')
      resp = double(channel: ch)
      allow(api_client).to receive(:channels_create).and_return(resp)
      allow(api_client).to receive(:channels_invite)
      allow(bot_client).to receive(:auth_test).and_return(double(user_id: 'uid'))
      allow(bot_client).to receive(:chat_postMessage).twice
    end

    let(:channel) do
      Channel.new(name: 'channel', master: '@master')
    end

    it 'creates channel' do
      expect { channel.save_with_slack }.not_to raise_error
    end
  end

  describe '#default_channel?' do
    let(:channel) { Channel.new(name: name) }

    context 'with normal name' do
      let(:name) { 'channel' }

      it 'returns false' do
        expect(channel).not_to be_default_channel
      end
    end

    context 'with name started underscore' do
      let(:name) { '_channel' }

      it 'returns true' do
        expect(channel).to be_default_channel
      end
    end
  end

  describe '#archive' do
    let(:channel) do
      Channel.create(
        cid: 'cid',
        name: 'channel',
        master: '@user'
      )
    end
    let(:client) do
      double('SlackClient')
    end

    before do
      allow(SlackClient).to receive(:build_api_client).and_return(client)
      allow(client).to receive(:channels_archive)
    end

    it 'archive channel' do
      channel.archive
      expect(channel.active).to eq(false)
      expect(channel.archived_at).to be <= Time.zone.now
    end
  end
end