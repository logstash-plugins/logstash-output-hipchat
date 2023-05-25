# encoding: utf-8
require_relative "../spec_helper"
require "logstash/outputs/hipchat"
require "logstash/event"

describe LogStash::Outputs::HipChat do
  let(:token) { "secret" }
  let(:message) { "foobar" }
  let(:event) { LogStash::Event.new({ "message" => message }) }
  let(:room_id) { "secret-lair" }
  let(:from) { "computer" }
  let(:trigger_notify) { true }
  let(:color) { "yellow" }
  let(:message_format) { "html" }
  let(:options) {
    { 
      "token" => token,
      "room_id" => room_id,
      "from" => from,
      "color" => color,
      "trigger_notify" => trigger_notify
    }
  }
  let(:hipchat) { double("hipchat") }
  let(:output) { LogStash::Outputs::HipChat.new(options) }

  before do
    output.register
  end

  shared_examples "sending events" do
    it "send the events" do
      expect(hipchat).to receive(:send).with(from, message, :notify => trigger_notify, :color => color, :message_format => message_format)
      output.receive(event)
    end

    context "String interpolation" do
      let(:event) {
        LogStash::Event.new({ "message" => message,
                              "my_room" => room_id,
                              "my_color" => color,
                              "from_who" => from})
      }

      let(:options) {
        super().merge({
          "token" => "secret",
          "room_id" => "%{my_room}",
          "from" => "%{from_who}",
          "color" => "%{my_color}",
          "trigger_notify" => trigger_notify
        })
      }

      it "applies string interpolation" do
        expect(hipchat).to receive(:send).with(from, message, :notify => trigger_notify, :color => color, :message_format => message_format)
        output.receive(event)
      end
    end
  end

  context "default host" do
    before do
      expect(HipChat::Client).to receive(:new).with(token, :api_version => "v2").and_return({ room_id => hipchat })
    end

    include_examples "sending events"
  end

  context "specified host" do
    let(:host) { "local.dev" }
    let(:options) { super().merge({ "host" => host }) }

    before do
      expect(HipChat::Client).to receive(:new).with(token, :api_version => "v2", :server_url => "https://#{host}").and_return({ room_id => hipchat })
    end

    include_examples "sending events"
  end
end
