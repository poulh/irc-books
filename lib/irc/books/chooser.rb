# frozen_string_literal: true

require 'irc/books/search_model'
require 'irc/books/questions'
# class for choosing menus

module Irc
  module Books
    # cli interface for searching and downloading ebooks
    class Chooser
      INFO_REGEX = '::INFO::'

      SEARCH = :search
      DOWNLOAD = :download
      MAIN_MENU = :main_menu
      QUIT = :quit

      EVENTS = %i[choice main_menu quit].freeze

      def initialize(search_model)
        @search_model = search_model

        @callbacks = {}

        @cli = HighLine.new

        @downloaders = {}
        @preferred_downloader = nil
      end

      def yield_choice(choice)
        @callbacks[:choice].call(choice)
      end

      def do_quit
        @callbacks[:quit].call
      end

      def on(event, &block)
        raise "invalid chooser event #{event}" unless EVENTS.include?(event)

        @callbacks[event] = block
      end

      def ask_nickname
        nick = @cli.ask Question.nickname
        yield(nick)
      end

      def choose_default_search_suffix
        @search_model.search_suffix = @cli.ask('What would you like the search suffix to be?')
      end

      def choose_preferences
        @cli.choose do |pref_menu|
          pref_menu.prompt = 'Select Preferences to change'

          main_menu_choice(pref_menu)

          pref_menu.choice("Choose Default Search Bot (#{@search_model.search_bot})") do
            choose_default_search_bot
          end

          pref_menu.choice("Change Search Suffix (#{@search_model.search_suffix})") do
            choose_default_search_suffix
          end

          pref_menu.choice("Change Download Path (#{@search_model.download_path})") do
            @search_model.download_path = @cli.ask(Question.download_path)
          end

          unless @downloaders.empty?
            pref_downloader = @preferred_downloader ? " (#{@preferred_downloader})" : ''
            pref_menu.choice("Change Default Downloader#{pref_downloader}") do
              choose_default_downloader
            end
          end
        end
      end

      def main_menu
        @cli.choose do |main_menu|
          main_menu.prompt = 'What do you want to do?'

          main_menu.choice('Search For Books') do
            search_for_books
          end

          unless @search_model.searches.empty?
            main_menu.choice("Active Searches (#{@search_model.searches.size})") do
              @search_model.searches.each do |_search_bot, bot_searches|
                bot_searches.each do |_cleaned_search, search|
                  puts "#{search[:search_bot]} #{search[:status]} - #{search[:phrase]}"
                end
              end
            end
          end

          unless @search_model.search_results.empty?
            main_menu.choice("Search Results (#{@search_model.search_results.size})") do
              choose_results
            end
          end

          unless @search_model.downloads.empty?
            main_menu.choice("View Downloads (#{@search_model.downloads.size})") do
              puts @search_model.downloads.join("\n")
            end
          end

          main_menu.choice('Preferences') do
            choose_preferences
          end

          main_menu_choice(main_menu,choice_name='Refresh')

          main_menu.choice('Quit') do
            do_quit
          end
        end
      end

      def main_menu_choice(menu, choice_name='Main Menu')
        menu.choice(choice_name) do
          @callbacks[:main_menu].call
        end
        menu.default = choice_name
      end

      def choose_default_downloader
        return if @downloaders.empty?

        @cli.choose do |downloader_menu|
          downloader_menu.prompt = 'Who would you like to download from?'
          main_menu_choice(downloader_menu)
          @downloaders.each do |downloader, _|
            downloader_menu.choice(downloader) do
              @preferred_downloader = downloader
            end
          end
        end
      end

      def choose_books(search, preferred_downloader)
        return unless @search_model.search_results.key?(search)

        books = @search_model.search_results[search]
        @cli.choose do |book_menu|
          book_menu.prompt = 'Which book would you like to download?'

          main_menu_choice(book_menu)

          if preferred_downloader
            book_menu.choice('See results from all downloaders') do
              choose_books(search, nil)
            end
          end

          books.keys.sort.each do |title|
            downloaders = books[title]
            downloaders.each do |downloader|
              next if preferred_downloader && (downloader != preferred_downloader)

              the_choice = [downloader, title].join(' ')
              book_menu.choice(the_choice) do
                yield_choice(command: DOWNLOAD, download_bot: downloader, title: title, phrase: the_choice)
                if downloader != @preferred_downloader
                  answer = @cli.ask("Make #{downloader} your preferred downloader? (y/n)")
                  @preferred_downloader = downloader if answer.downcase[0] == 'y'
                  preferred_downloader = @preferred_downloader
                end
                choose_books(search, preferred_downloader)
              end
            end
          end
        end
      end

      def choose_results
        @cli.choose do |results_menu|
          results_menu.prompt = 'Which search results would you like to view?'

          main_menu_choice(results_menu)

          @search_model.search_results.each do |search, results|
            results_menu.choice("#{search[:phrase]} (#{results.keys.size})") do
              choose_default_downloader unless @preferred_downloader
              choose_books(search, @preferred_downloader)
            end
          end
        end
      end

      def choose_default_search_bot
        @cli.choose do |bot_menu|
          bot_menu.prompt = 'Which search bot would you like to use?'
          main_menu_choice(bot_menu)
          @search_model.search_bots.each do |bot|
            bot_menu.choice(bot + (bot == @search_model.search_bot ? '*' : '')) do
              @search_model.search_bot = bot
            end
          end
        end
      end

      def add_results(search, results)
        @search_model.searches.delete(search)
        @search_model.search_results[search] = results
        results.each do |_title, downloaders|
          downloaders.each do |downloader|
            @downloaders[downloader] = true
          end
        end
      end

      def request_download
        nil
      end

      def check_initialized
        EVENTS.each do |event|
          raise "#{event} callback not initialized" unless @callbacks[event]
        end
      end

      def beep
        puts "\a"
      end

      def notify_wait_on_join
        puts "This channel has a mandatory #{@search_model.wait_time} second wait time when joining"
      end

      def notify_search_in_progress(search)
        puts "Search in Progress: #{search[:phrase]}"
      end

      def notify_no_search_results_found(search)
        puts "No Search Results Found: #{search[:phrase]}"
      end

      def notify_error_in_search_result(search)
        puts "Unknown Search Result: #{search[:phrase]}"
      end

      def notify_search_results_found(search)
        puts "New Search Results:: #{search[:phrase]}"
      end

      def notify_download_request_in_progress(search)
        puts "Download in Progress: #{search[:phrase]}"
      end

      def notify_book_downloaded(search)
        puts "New Download: #{search[:phrase]}"
      end

      def search_for_books
        title = @cli.ask('What books would you like to search for? (Press <Return> for Main Menu)')
        case title.downcase
        when ''
          @callbacks[:main_menu].call
        else
          yield_choice(command: SEARCH, phrase: title)
        end
      end
    end
  end
end
