# frozen_string_literal: true

require 'irc/books/search_model'
require 'irc/books/questions'
require 'irc/books/book_sorter'
require 'irc/books/menu_loop'
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
        Irc::Books::MenuLoop.new do |ml|
          @cli.choose do |pref_menu|
            pref_menu.prompt = 'Select Preferences to change'

            ml.go_back_choice(pref_menu, 'Main Menu')

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
        end # end loop
      end

      def main_menu
        Irc::Books::MenuLoop.new do |_ml|
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
                choose_search_results
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

            refresh = 'Refresh'
            main_menu.choice(refresh)
            main_menu.default = refresh

            main_menu.choice('Quit') do
              do_quit
            end
          end
        end
      end

      def main_menu_choice(menu, choice_name = 'Main Menu')
        menu.choice(choice_name) do
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

      def choose_books(search, _preferred_downloader)
        return unless @search_model.search_results.key?(search)

        Irc::Books::MenuLoop.new do |ml|
          @cli.choose do |book_menu|
            book_menu.prompt = 'Which book would you like to download?'
            ml.go_back_choice(book_menu, 'Main Menu')

            books = @search_model.search_results[search]
            Irc::Books::BookSorter.display_each_book(books) do |book_display_name, book, idx, total_count|
              last_menu_number = total_count + 1
              menu_number = idx + 2 # 1 for zero based, one for first item is Main Menu
              ljust_shift = last_menu_number.to_s.length - menu_number.to_s.length
              # puts "#{total_count} #{total_count.to_s.length} #{idx} #{idx.to_s.length} #{menu_number} #{menu_number.to_s.length} #{}"
              # ljust_shift = total_count.to_s.length - idx.to_s.length
              ljust_shift_str = " " * ljust_shift

              book_menu.choice(ljust_shift_str + book_display_name) do
                yield_choice(command: DOWNLOAD, download_bot: book[:source], title: book[:filename], phrase: book[:line])
              end
            end
          end
        end
      end

      def choose_search_results
        @cli.choose do |results_menu|
          results_menu.prompt = 'Which search results would you like to view?'

          main_menu_choice(results_menu)

          @search_model.search_results.each do |search, results|
            results_menu.choice("#{search[:phrase]} (#{results.size})") do
              # choose_default_downloader unless @preferred_downloader
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
        Irc::Books::MenuLoop.new do |ml|
          title = @cli.ask('What books would you like to search for? (Press <Return> for Main Menu)')
          case title.downcase
          when ''
            ml.go_back
          else
            yield_choice(command: SEARCH, phrase: title)
          end
        end
      end
    end
  end
end
