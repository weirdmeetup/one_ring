# frozen_string_literal: true

require "rails_helper"

describe WarningJob, type: :job do
  let(:job) { described_class.new }
  let(:channel_name) { "channel" }
  let(:warned_at) { nil }
  let!(:channel) do
    Channel.create(
      cid: "cid",
      name: channel_name,
      master: "@user",
      active: "true",
      warned_at: warned_at,
      created_at: 10.days.ago
    )
  end

  describe "#perform" do
    before do
      allow(SlackClient).to receive(:post_msg_as_bot)
      allow(SlackClient).to receive(:post_msg_to_manager)
    end

    context "with inactive candidate" do
      it "works properly" do
        job.perform
        expect(channel.reload.warned_at).not_to be_nil
      end

      context "with already warned" do
        let(:warned_at) { 2.days.ago }

        it "skips" do
          job.perform
          expect(channel.reload.warned_at).not_to be_nil
        end
      end
    end

    context "with not inactive candidate" do
      let(:channel_name) { "_channel" }
      let(:warned_at) { 2.days.ago }

      it "reset warned_at" do
        job.perform
        expect(channel.reload.warned_at).to be_nil
      end
    end
  end
end
