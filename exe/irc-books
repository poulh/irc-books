#!/usr/bin/ruby

require 'cinch'
require 'cinch/helpers'
require 'zip'
require 'highline'
require 'shellwords'
require 'tempfile'
require 'fileutils'

INFO = '::INFO::'.freeze
EBOOKS = '#ebooks'.freeze

# class for choosing menus
class Chooser
  def initialize
    @block = nil

    @cli = HighLine.new

    @search_bots = []
    @search_bot = 'searchook'
    @search_suffix = 'epub rar'
    choose_default_path('~/Downloads/ebooks')

    @searches = {}
    @results = {}
    @downloads = []

    @downloaders = {}
    @preferred_downloader = nil
  end

  def do_yield(cmd)
    @block.call(cmd) if @block
  end

  def quit
    do_yield('quit')
  end

  def choose_default_search_suffix
    @search_suffix = @cli.ask('What would you like the search suffix to be?')
  end

  def choose(&block)
    @block = block
    main_menu
  end

  def choose_preferences
    @cli.choose do |pref_menu|
      pref_menu.prompt = 'Select Preferences to change'

      main_menu_choice(pref_menu)

      pref_menu.choice("Choose Default Search Bot (#{@search_bot})") do
        choose_default_search_bot
      end

      pref_menu.choice("Change Search Suffix (#{@search_suffix})") do
        choose_default_search_suffix
      end

      pref_menu.choice("Change Download Path (#{@download_path})") do
        new_path = @cli.ask('What would you like the download path to be?') { |answer| answer.default = '' }
        choose_default_path(new_path) unless new_path.empty?
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
        quit
      end
    end
  end

  def choose_default_path(path)
    @download_path = File.expand_path(path)
  end

  def set_search_bots(bots)
    @search_bots = bots
    if @search_bot && @search_bots.include?(@search_bot)
      nil
    else
      @search_bot = @search_bots.first
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
      @search_bots.each do |bot|
        bot_menu.choice(bot + (bot == @search_bot ? '*' : '')) do
          @search_bot = bot
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
      search_phrase = "#{title} #{@search_suffix}"
      search = {
        phrase: search_phrase,
        bot: @search_bot,
        cmd: "@#{@search_bot} #{search_phrase}"
      }
      @searches[search] = false
      do_yield(search[:cmd])

    end
  end

  def accept_file(user, filename, file)
    matches = @searches.keys.select { |search| search[:bot] == user && filename.index(search[:phrase].tr(' ', '_')) }

    file_path = file.path
    if matches.empty?
      new_path = File.join(@download_path, filename)
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
          next unless result =~ /#{INFO}/

          result = result[0, result.index(INFO)].strip
          owner, title = result.split(' ', 2)
          books[title] = [] unless books.key?(title)
          books[title] << owner
        end

        matches.each do |match|
          add_results(match, books)
          puts "New Search Results: #{match[:phrase]}"
        end
      end
    rescue StandardError => error
      puts "error: #{error}"
    ensure
      file.unlink
    end
  end
end

def on_next
  Timer(1, shots: 1) do
    yield
  end
end

def main
  cli = HighLine.new

  nick = cli.ask 'What is your nickname?'
  bot = Cinch::Bot.new do
    chooser = Chooser.new

    configure do |conf|
      conf.server = 'irc.irchighway.net'
      conf.channels = [EBOOKS]
      conf.nick = nick
    end

    on :connect do |_msg|
      nil
    end

    on :join do |msg|
      if msg.user == bot.nick
        topic = msg.channel.topic.strip
        search_bots = topic.split.select { |word| word.match(/@.*/) }
        search_bots = search_bots.collect { |botnames| botnames.delete('@').downcase }
        chooser.set_search_bots(search_bots)

        on_next do
          begin
            running = true
            loop do
              break unless running

              chooser.choose do |cmd|
                if cmd == 'quit'
                  running = false
                else
                  on_next do
                    Channel(EBOOKS).send(Sanitize(cmd))
                  end
                end
              end
            end
          rescue StandardError => error
            puts "error: #{error}"
          ensure
            bot.quit
            sleep(2)
            exit
          end
        end

      end
    end

    on :dcc_send do |msg, dcc|
      user = msg.user.nick.downcase
      begin
        filename = dcc.filename
        file = Tempfile.new(filename)
        dcc.accept(file)
        file.close
        chooser.accept_file(user, filename, file)
      end
    end

    on :private do |msg, _dcc|
      chooser.parse_private_msg(msg.user.nick.downcase, Sanitize(msg.message))
    end

    on :message do |_msg|
      nil
    end
  end

  bot.loggers.level = :fatal
  bot.start
end

main
