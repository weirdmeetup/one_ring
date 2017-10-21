require 'rails_helper'

describe ArchivingJob, type: :job do
  let(:job) { described_class.new }
  let(:client) { double('SlackClient') }
  let(:warned_at) { 30.days.ago }
  let!(:channel) do
    Channel.create(
      cid: 'cid',
      name: 'channel',
      master: '@user',
      active: 'true',
      warned_at: warned_at
    )
  end

  describe '#perform' do
    before do
      allow(SlackClient).to receive(:build_bot_client).and_return(client)
    end

    context 'with target' do
      it 'tries archive' do
        expect_any_instance_of(Channel).to receive(:archive)
        expect(client).to receive(:chat_postMessage)
        job.perform
      end
    end

    context 'with not target' do
      let(:warned_at) { nil }

      it 'do nothing' do
        expect(client).not_to receive(:chat_postMessage)
        job.perform
      end
    end
  end
end
