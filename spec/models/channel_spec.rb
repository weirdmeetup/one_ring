# frozen_string_literal: true

require "rails_helper"

describe Channel, type: :model do
  describe ".init_with" do
    let(:api_client) { double("SlackApiClient") }
    let(:bot_client) { double("SlackBotClient") }
    let(:master) { "master" }

    before do
      allow(SlackClient).to receive(:build_api_client).and_return(api_client)
      allow(SlackClient).to receive(:build_bot_client).and_return(bot_client)
      ch = double(id: "cid")
      resp = double(channel: ch)
      allow(api_client).to receive(:channels_create).and_return(resp)
      allow(api_client).to receive(:channels_invite)
      allow(bot_client).to receive(:auth_test).and_return(double(user_id: "uid"))
      allow(bot_client).to receive(:chat_postMessage)
      allow(api_client).to receive(:chat_postMessage)
      members = [
        double(id: "uid", profile: double(display_name: master))
      ]
      allow(api_client).to receive(:users_list).and_return(double(members: members))
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
    let(:api_client) { double("SlackApiClient") }
    let(:bot_client) { double("SlackBotClient") }

    before do
      allow(SlackClient).to receive(:build_api_client).and_return(api_client)
      allow(SlackClient).to receive(:build_bot_client).and_return(bot_client)
      allow(api_client).to receive(:channels_unarchive)
      allow(api_client).to receive(:channels_invite)
      allow(bot_client).to receive(:auth_test).and_return(double(user_id: "uid"))
      allow(bot_client).to receive(:chat_postMessage)
      allow(api_client).to receive(:chat_postMessage)
      members = [
        double(id: "uid", profile: double(display_name: master))
      ]
      allow(api_client).to receive(:users_list).and_return(double(members: members))
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
      allow(SlackClient).to receive(:build_api_client).and_return(client)
      allow(client).to receive(:channels_archive)
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

    context "with no messages" do
      let(:created_at) { 8.days.ago }

      it "returns true" do
        expect(channel).to be_inactive_candidate
      end
    end

    context "with last message created 8 day" do
      let(:created_at) { 8.days.ago }

      it "returns true" do
        Message.create(
          channel_id: channel.id,
          user: "user",
          text: "text",
          raw: "",
          created_at: 8.days.ago
        )
        expect(channel).to be_inactive_candidate
      end
    end

    context "with created in 7 days" do
      let(:created_at) { 4.days.ago }

      it "returns false" do
        expect(channel).not_to be_inactive_candidate
      end
    end

    context "with default channels" do
      let(:channel_name) { "_general" }

      it "returns true" do
        expect(channel).not_to be_inactive_candidate
      end
    end
  end

  describe "#inactive?" do
    let(:channel) do
      Channel.create(
        cid: "cid",
        name: "channel",
        master: "user",
        warned_at: warned_at,
        created_at: created_at
      )
    end
    let(:warned_at) { nil }
    let(:created_at) { nil }

    context "with active channel" do
      it "returns false" do
        expect(channel).not_to be_inactive
      end
    end

    context "with warned & has message in 20 days channel" do
      let(:warned_at) { 13.days.ago }

      it "returns true" do
        Message.create(
          channel_id: channel.id,
          user: "user",
          text: "text",
          raw: "",
          created_at: 20.days.ago
        )
        expect(channel).not_to be_inactive
      end
    end

    context "with warned & has no messages in 30 days channel" do
      let(:warned_at) { 23.days.ago }

      it "returns true" do
        expect(channel).to be_inactive
      end
    end

    context "with warned & has message in 35 days channel" do
      let(:warned_at) { 29.days.ago }

      it "returns true" do
        Message.create(
          channel_id: channel.id,
          user: "user",
          text: "text",
          raw: "",
          created_at: 35.days.ago
        )
        expect(channel).to be_inactive
      end
    end
  end
end
