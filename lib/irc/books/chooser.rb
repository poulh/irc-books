# frozen_string_literal: true

require 'irc/books/search_model'
require 'irc/books/questions'
# class for choosing menus

module Irc
  module Books
    class Chooser
      INFO_REGEX = '::INFO::'

      def initialize(model)
        @model = model

        @block = nil
        @quit_block = nil

        @cli = HighLine.new

        @searches = {}
        @results = {}
        @downloads = []

        @downloaders = {}
        @preferred_downloader = nil
      end

      def do_yield(text)
        @block.call(text)
      end

      def do_quit
        @quit_block.call
      end

      def on_choice(&block)
        @block = block
      end

      def on_quit(&block)
        @quit_block = block
      end

      def ask_nickname
        nick = @cli.ask Question.nickname
        yield(nick)
      end

      def choose_default_search_suffix
        @model.search_suffix = @cli.ask('What would you like the search suffix to be?')
      end

      def choose_preferences
        @cli.choose do |pref_menu|
          pref_menu.prompt = 'Select Preferences to change'

          main_menu_choice(pref_menu)

          pref_menu.choice("Choose Default Search Bot (#{@model.search_bot})") do
            choose_default_search_bot
          end

          pref_menu.choice("Change Search Suffix (#{@model.search_suffix})") do
            choose_default_search_suffix
          end

          pref_menu.choice("Change Download Path (#{@model.download_path})") do
            @model.download_path = @cli.ask('What would you like the download path to be?') { |answer| answer.default = '' }
          end

          unless @downloaders.empty?
            pref_downloader = @preferred_downloader ? " (#{@preferred_downloader})" : ''
            pref_menu.choice("Change Default Downloader#{pref_downloader}") do
              choose_default_downloader
            end
          end
        end
      end

      def main_menu_loop
        loop do
          main_menu
        end
      end

      def main_menu
        @cli.choose do |main_menu|
          main_menu.prompt = 'What do you want to do?'

          main_menu.choice('Search For Books') do
            search
          end

          unless @searches.empty?
            main_menu.choice("Active Searches (#{@searches.size})") do
              @searches.each do |search, accepted|
                state = accepted ? 'x' : '?'
                puts "#{search[:bot]} #{state} - #{search[:phrase]}"
              end
            end
          end

          unless @results.empty?
            main_menu.choice("Search Results (#{@results.size})") do
              choose_results
            end
          end

          unless @downloads.empty?
            main_menu.choice("View Downloads (#{@downloads.size})") do
              puts @downloads.join("\n")
            end
          end

          main_menu.choice('Preferences') do
            choose_preferences
          end

          refresh = 'Refresh'

          main_menu.choice(refresh) do
            nil
          end

          main_menu.default = refresh

          main_menu.choice('Quit') do
            do_quit
          end
        end
      end

      def main_menu_choice(menu)
        mm = 'Main Menu'
        menu.choice(mm) do
          nil
        end
        menu.default = mm
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
        return unless @results.key?(search)

        books = @results[search]
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
                do_yield(the_choice)
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

          @results.each do |search, results|
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
          @model.search_bots.each do |bot|
            bot_menu.choice(bot + (bot == @model.search_bot ? '*' : '')) do
              @model.search_bot = bot
            end
          end
        end
      end

      def add_results(search, results)
        @searches.delete(search)
        @results[search] = results
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
        raise 'choice callback not initialized' unless @block
        raise 'quit callback not initialized' unless @quit_block
        raise 'search bot not initialized' unless @model.search_bot
      end

      def choose
        check_initialized

        main_menu_loop
      rescue StandardError => e
        puts e
        exit
      end

      def parse_private_msg(user, msg)
        no_results = msg.index('Sorry')
        matches = @searches.keys.select { |search| search[:bot] == user && msg.index(search[:phrase]) }
        matches.each do |match|
          match_phrase = match[:phrase]
          if no_results
            add_results(match, {})
            puts "No Results for Search: #{match_phrase}"
          elsif !(@searches[match])
            @searches[match] = true
            puts "Search in Progress: #{match_phrase}"
          end
        end
      end

      def search
        title = @cli.ask('What books would you like to search for? (type M to return to Main Menu)')
        case title.downcase
        when 'm'
          main_menu
        else
          search_phrase = "#{title} #{@model.search_suffix}"
          search = {
            phrase: search_phrase,
            bot: @model.search_bot,
            cmd: "@#{@model.search_bot} #{search_phrase}"
          }
          @searches[search] = false
          do_yield(search[:cmd])
        end
      end

      def accept_file(user, filename, file)
        matches = @searches.keys.select { |search| search[:bot] == user && filename.index(search[:phrase].tr(' ', '_')) }

        file_path = file.path
        if matches.empty?
          new_path = File.join(@model.download_path, filename)
          FileUtils.mv(file_path, new_path, verbose: false)
          @downloads << new_path
          puts "New Download: #{new_path}"
          return
        end

        begin
          zipfile = Zip::File.open(file_path)

          zipfile.entries.each do |entry|
            books = {}
            results = zipfile.read(entry.name).split(/[\r\n]+/)
            results.each do |result|
              next unless result =~ /^!.*/
              next unless result =~ /#{INFO_REGEX}/

              result = result[0, result.index(INFO_REGEX)].strip
              owner, title = result.split(' ', 2)
              books[title] = [] unless books.key?(title)
              books[title] << owner
            end

            matches.each do |match|
              add_results(match, books)
              puts "New Search Results: #{match[:phrase]}"
            end
          end
        rescue StandardError => e
          puts "error: #{e}"
        ensure
          file.unlink
        end
      end
    end
  end
end