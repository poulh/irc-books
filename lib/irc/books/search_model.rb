# frozen_string_literal: true

module Irc
  module Books
    class SearchModel
      attr_accessor :search_bots, :search_suffix
      attr_accessor :active_searches, :downloads, :search_results, :nickname, :downloaders
      attr_reader :download_path, :searches, :wait_time
      def initialize(options)
        @nickname = options[:nickname]
        @search_bots = []
        @active_searches = {}
        @search_results = {}
        @downloads = []

        @wait_time = 30

        @search_suffix = 'epub'
        self.download_path = '~/Downloads/ebooks'
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
      def search_phrase(phrase)
        "#{phrase} #{search_suffix}"
      end

      def self.clean_search_phrase(search_phrase)
        search_phrase.tr(' ', '_')
      end

      def add_search(phrase)
        search_phrase = search_phrase(phrase)

        search = {
          phrase: search_phrase,
          search_bot: search_bot,
          status: :in_transit
        }

        bot_searches = @searches.fetch(search_bot) do |search_bot|
          @searches[search_bot] = {}
        end

        bot_searches[SearchModel.clean_search_phrase(search_phrase)] = search
      end

      def select_search(search_bot, search)
        clean_search_phrase = SearchModel.clean_search_phrase(search[:phrase])

        bot_searches = @searches.fetch(search_bot)

        selected = bot_searches.select do |cleaned_search, bot_search|
          return bot_search if clean_search_phrase.index(cleaned_search)
        end
        raise KeyError if selected.empty?

        selected.first
      end

      def update_existing_search(search)
        bot_searches = @searches.fetch(search[:search_bot])
        cleaned_search = SearchModel.clean_search_phrase(search[:phrase])
        bot_searches.fetch(cleaned_search) # raise KeyError if not there
        bot_searches[cleaned_search] = search
      end
    end
  end
end
