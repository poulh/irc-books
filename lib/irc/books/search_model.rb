# frozen_string_literal: true

module Irc
  module Books
    class SearchModel
      attr_accessor :search_bots, :search_suffix
      attr_accessor :active_searches, :downloads, :search_results, :nickname
      attr_reader :download_path, :searches
      def initialize
        @search_bots = []
        @active_searches = {}
        @search_results = {}
        @downloads = []

        @search_suffix = 'epub'
        @download_path = '~/Downloads/ebooks'
        @searches = {}
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

      # def set_search_status(search, status)
      #   searches[search] = status
      #   [search, status]
      # end

      def add_search(phrase)
        search_phrase = "#{phrase} #{search_suffix}"
        search = {
          phrase: search_phrase,
          bot: search_bot
        }
        searches[search] = :in_transit
        [search, :in_transit]
      end

      def set_search_status(search, status)
        matches = searches.keys.select do |key|
          key[:bot] == search[:bot] && \
            search[:phrase].index(key[:phrase])
        end

        return [search, :error] if matches.empty?

        match = matches.first

        searches[match] = status
        [match, status]
      end
    end
  end
end
