# frozen_string_literal: true

require "rails_helper"

describe Channel, type: :model do
  describe ".init_with" do
    let(:master) { "master" }

    before do
      ch = double(id: "cid")
      resp = double(channel: ch)
      allow(SlackClient).to receive(:channels_create).and_return(resp)
      allow(SlackClient).to receive(:channels_invite)
      allow(SlackClient).to receive(:channels_leave)
      allow(SlackClient).to receive(:bot_uid).and_return("bot_uid")
      allow(SlackClient).to receive(:post_msg_as_bot)
      allow(SlackClient).to receive(:post_msg_via_api)
      allow(SlackClient).to receive(:users_info).and_return(double(id: 'uid'))
    end

    let(:channel) do
      Channel.new(name: "channel", master: master)
    end

    it "creates channel" do
      expect { channel.save_with_slack }.not_to raise_error
    end
  end

  describe "#default_channel?" do
    let(:channel) { Channel.new(name: name) }

    context "with normal name" do
      let(:name) { "channel" }

      it "returns false" do
        expect(channel).not_to be_default_channel
      end
    end

    context "with name started underscore" do
      let(:name) { "_channel" }

      it "returns true" do
        expect(channel).to be_default_channel
      end
    end
  end

  describe "#unarchive" do
    let(:channel) do
      Channel.create(
        cid: "cid",
        name: channel_name,
        master: master,
        active: false,
        archived_at: 10.days.ago
      )
    end
    let(:channel_name) do
      "channel"
    end
    let(:master) do
      "master"
    end

    before do
      allow(SlackClient).to receive(:channels_unarchive)
      allow(SlackClient).to receive(:channels_invite)
      allow(SlackClient).to receive(:channels_leave)
      allow(SlackClient).to receive(:bot_uid).and_return("bot_uid")
      allow(SlackClient).to receive(:post_msg_as_bot)
      allow(SlackClient).to receive(:post_msg_via_api)
      allow(SlackClient).to receive(:users_info).and_return(double(id: 'uid'))
    end

    context "with valid condition" do
      it "unarchive channel" do
        channel.unarchive
        expect(channel.active).to eq(true)
        expect(channel.archived_at).to be_nil
      end
    end

    context "with empty master" do
      it "fails to unarchive channel" do
        channel.master = nil
        expect(channel.unarchive).to eq(false)
        expect(channel.active).to eq(false)
        expect(channel.archived_at).not_to be_nil
      end
    end
  end

  describe "#archive" do
    let(:channel) do
      Channel.create(
        cid: "cid",
        name: channel_name,
        master: "user"
      )
    end
    let(:channel_name) do
      "channel"
    end
    let(:client) do
      double("SlackClient")
    end

    before do
      allow(SlackClient).to receive(:channels_archive)
      allow(SlackClient).to receive(:post_msg_as_bot)
    end

    it "archive channel" do
      channel.archive
      expect(channel.active).to eq(false)
      expect(channel.archived_at).to be <= Time.zone.now
    end
  end

  describe "#inactive_candidate?" do
    let(:channel) do
      Channel.create(
        cid: "cid",
        name: "channel",
        master: "user",
        created_at: created_at
      )
    end
    let(:created_at) { nil }

  end

  describe "#inactive_candidate?" do
    let(:channel) do
      Channel.create(
        cid: "cid",
        name: channel_name,
        master: "user",
        created_at: created_at,
        active: active
      )
    end

    let(:active) { true }
    let(:channel_name) { "general" }
    let(:created_at) { 20.days.ago }

    context "with inactive channel" do
      let(:active) { false }

      it "returns false" do
        expect(channel).not_to be_inactive_candidate
      end
    end

    context "with default channel" do
      let(:channel_name) { "_general" }

      it "returns false" do
        expect(channel).not_to be_inactive_candidate
      end
    end

    context "with created in 14 days" do
      let(:created_at) { 13.days.ago }

      it "returns false" do
        expect(channel).not_to be_inactive_candidate
      end
    end

    context "with no messages" do
      it "returns true" do
        expect(channel).to be_inactive_candidate
      end
    end

    context "with last message" do
      let(:message) do
        Message.create(
          channel_id: channel.id,
          user: "user",
          text: "text",
          raw: "",
          created_at: message_sent_at
        )
      end

      context "sent 10 days ago" do
        let(:message_sent_at) { 10.days.ago }

        it "returns true" do
          Message.create(
            channel_id: channel.id,
            user: "user",
            text: "text",
            raw: "",
            created_at: message_sent_at
          )
          expect(channel).not_to be_inactive_candidate
        end
      end

      context "sent 15 days ago" do
        let(:message_sent_at) { 15.days.ago }

        it "returns true" do
          Message.create(
            channel_id: channel.id,
            user: "user",
            text: "text",
            raw: "",
            created_at: message_sent_at
          )
          expect(channel).to be_inactive_candidate
        end
      end
    end
  end
end
