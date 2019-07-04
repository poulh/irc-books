# frozen_string_literal: true

module Irc
  module Books
    class SearchModel
      attr_accessor :nickname, :search_bots, :active_searches, :search_results, :downloads
      attr_reader :download_path
      def initialize
        @search_bots = []
        @active_searches = {}
        @search_results = {}
        @downloads = []

        @download_path = '~/Downloads/ebooks'
      end

      def search_bot
        return @search_bot if @search_bot

        search_bots.first
      end

      def search_bot=(bot)
        raise "invalid search bot: #{bot}" unless search_bots.include?(bot)

        @search_bot = bot
      end

      def download_path=(path)
        return if path.empty?

        @download_path = File.expand_path(path)
      end
    end
  end
end
