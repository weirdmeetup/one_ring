# frozen_string_literal: true

require "rails_helper"

describe ArchivingJob, type: :job do
  let(:job) { described_class.new }
  let(:message_sent_at) { 30.days.ago }
  let!(:channel) do
    Channel.create(
      cid: "cid",
      name: "channel",
      master: "@user",
      active: "true",
      created_at: 30.days.ago
    )
  end

  describe "#perform" do
    before do
      allow(SlackClient).to receive(:post_msg_as_bot)
      allow(SlackClient).to receive(:post_msg_to_manager)
      allow(SlackClient).to receive(:post_msg_via_api)
    end

    context "with target" do
      it "tries archive" do
        expect_any_instance_of(Channel).to receive(:archive)
        job.perform
      end
    end

    context "with not target" do
      let!(:message) do
        Message.create(
          channel_id: channel.id,
          user: "user",
          text: "text",
          raw: ""
        )
      end

      it "do nothing" do
        expect_any_instance_of(Channel).not_to receive(:archive)
        job.perform
      end
    end
  end
end
