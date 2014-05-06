require 'net/http'
require 'uri'
require 'json'

require_relative 'slack-notifier/http_post'
require_relative 'slack-notifier/link_formatter'

module Slack
  class Notifier

    # these act as defaults
    # if they are set
    attr_accessor :channel, :username, :mrkdwn

    attr_reader :team, :token, :hook_name

    def initialize team, token, hook_name = default_hook_name
      @team  = team
      @token = token
      @hook_name = hook_name
    end

    def ping message, options={}
      message = LinkFormatter.format(message)
      payload = { text: message }.merge(default_payload).merge(options)

      HTTParty.post(endpoint, :body => {payload: payload.to_json})
    end

    def valid_token?
      r = HTTParty.get(endpoint)
      # debugger
      r.code == 200
    end

    def valid_channel? options={}
      channel = default_payload.merge(options)[:channel]
      raise "channel is required" unless channel

      r = HTTParty.post(endpoint, :body => {channels: channel})
      # debugger
      r.code == 202
    end

    def channel= channel
      @channel = if channel.start_with? '#', "@"
        channel
      else
        "##{channel}"
      end
    end

    private

      def default_hook_name
        'incoming-webhook'
      end

      def default_payload
        payload = {}
        payload[:channel]  = channel  if channel
        payload[:username] = username if username
        payload[:mrkdwn] = mrkdwn if mrkdwn
        payload
      end

      def endpoint
        "https://#{team}.slack.com/services/hooks/#{hook_name}?token=#{token}"
      end

  end
end
