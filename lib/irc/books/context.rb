# frozen_string_literal: true

require 'cinch'
require 'cinch/helpers'

require 'irc/books/chooser'
require 'irc/books/msg_parser'
require 'irc/books/search_model'
require 'irc/books/results_parser'

module Irc
  module Books
    # main class of application
    class Context
      attr_reader :bot
      attr_accessor :search_model, :chooser
      include Cinch::Helpers

      EBOOKS = '#ebooks'
      IRC_HIGHWAY_URL = 'irc.irchighway.net'

      def main_menu_on_join
        @chooser.notify_wait_on_join

        chooser_main_menu(wait_time = @search_model.wait_time, beep = true)
      end

      def chooser_main_menu(wait_time = 0, beep = false)
        on_next(wait_time = wait_time) do
          @chooser.check_initialized
          @chooser.beep if beep
          @chooser.main_menu
        end
      end

      def initialize(options)
        @bot = Cinch::Bot.new
        @bot.loggers.level = options[:log_level] || :error

        @search_model = Irc::Books::SearchModel.new(options)
        @chooser = Irc::Books::Chooser.new(@search_model)
      end

      def init_chooser_on_quit
        @chooser.on :quit do
          @bot.quit
          sleep(10)
        end
      end

      def init_chooser_on_menu
        @chooser.on :main_menu do
          chooser_main_menu
        end
      end

      def init_chooser_on_choice
        @chooser.on :choice do |choice|
          phrase = choice[:phrase]
          case choice[:command]
          when Irc::Books::Chooser::SEARCH
            search, status = @search_model.add_search(phrase)

            next if status == :error

            cmd = "@#{search[:search_bot]} #{search[:phrase]}"
            send_text_to_channel(EBOOKS, cmd)
            init_on_search_accepted(search)

          when Irc::Books::Chooser::DOWNLOAD
            send_text_to_channel(EBOOKS, phrase)
            init_on_download_book_accepted(choice)
          else
            puts "unknown command #{choice}"
          end
        end
      end

      def init_parse_search_bots_on_join
        @bot.on :join, //, self do |msg, ctxt|
          next unless Irc::Books::MsgParser.bot_nick_msg?(@bot, msg)

          ctxt.search_model.search_bots = Irc::Books::MsgParser.parse_search_bots_from_topic(msg)

          ctxt.main_menu_on_join
        end
      end

      def init_on_download_book_accepted(command)
        phrase = Regexp.escape(command[:title])
        regex_accepted = "^.*accepted.*#{phrase}.*$"

        @bot.loggers.info "registering download accepted: #{regex_accepted}"
        handler = @bot.on :private, /#{regex_accepted}/i, self do |_msg, context|
          context.chooser.notify_download_request_in_progress(phrase: command[:title])

          context.init_on_download_book_file(command)

          context.bot.handlers.unregister(handler)
        end
        handler
      end

      def init_on_download_book_file(command)
        phrase = Regexp.escape(command[:title])
        regex_book_file = "^.*#{phrase}.*$"
        @bot.loggers.info "regex book download file: #{regex_book_file}"
        handler = @bot.on :dcc_send, /#{regex_book_file}/i, self do |_msg, context, dcc|
          filename, file = Irc::Books::MsgParser.parse_and_accept_file(dcc)

          context.on_next do
            context_model = context.search_model

            new_path = File.join(context_model.download_path, filename)

            FileUtils.mkdir_p(context_model.download_path, verbose: true)
            FileUtils.mv(file.path, new_path, verbose: true)
            context_model.downloads << new_path

            context.chooser.notify_book_downloaded(phrase: new_path)
            context.chooser.beep
          end
          context.bot.handlers.unregister(handler)
        end
        handler
      end

      def init_on_search_accepted(search)
        regex_accepted = '^.*%{phrase}.*accepted.*$' % search
        @bot.loggers.info "registering: #{regex_accepted}"
        handler = @bot.on :private, /#{regex_accepted}/i, self do |_msg, context|
          context.chooser.notify_search_in_progress(search)
          handlers = []
          handlers << context.init_on_search_results_found(search, handlers)
          handlers << context.init_on_no_search_results_found(search, handlers)
        end
        handler
      end

      def self.unregister_handlers(context, handlers)
        handlers.each do |handl|
          context.bot.handlers.unregister(handl)
        end
      end

      def init_on_no_search_results_found(search, handlers)
        regex_no_results_found = '^.*%{phrase}.*returned .*no.* match.*$' % search
        @bot.loggers.info "registering: #{regex_no_results_found}"

        handler = @bot.on :private, /#{regex_no_results_found}/, self do |_msg, context|
          context.chooser.notify_no_search_results_found(search)
          Context.unregister_handlers(context, handlers)
        end
        handler
      end

      def init_on_search_results_found(search, handlers)
        regex_results_found = '^.*%{phrase}.*returned \d+ match.*$' % search
        @bot.loggers.info "registering: #{regex_results_found}"
        # Your search for "12,9Tom Clancy epub1,9" returned 1000 match

        handler = @bot.on :private, /#{regex_results_found}/, self do |_msg, context|
          context.init_on_search_results_file_download(search)
          # context.init_on_search_results_filename(search)

          Context.unregister_handlers(context, handlers)
        end
        handler
      end

      def init_on_search_results_filename(search)
        # two spaces on purpose after 'results for'
        regex_results_filename = '^.*results for  %{phrase}.*$' % search
        regex_results_filename.tr!(' ', '_')

        @bot.loggers.info "registering: #{regex_results_filename}"

        handler = @bot.on :private, /#{regex_results_filename}/, self do |_msg, context|
          context.bot.handlers.unregister(handler)
        end
        handler
      end

      def init_on_search_results_file_download(search)
        # two spaces on purpose after 'results for'
        regex_results_file_download = '^.*results for  %{phrase}.*$' % search
        regex_results_file_download.tr!(' ', '_')

        @bot.loggers.info "registering: #{regex_results_file_download}"

        handler = @bot.on :dcc_send, /#{regex_results_file_download}/, self do |_msg, context, dcc|
          filename, file = Irc::Books::MsgParser.parse_and_accept_file(dcc)
          @bot.loggers.info "#{filename} downloaded: #{file.path}"

          books = context.parse_search_results(file)
          context.search_model.search_results[search] = books
          context.chooser.notify_search_results_found(search)
          context.chooser.beep
          file.unlink
          context.bot.handlers.unregister(handler)
        end
        handler
      end

      def self.unzip_readlines(file)
        zipfile = Zip::File.open(file.path)
        zipfile.read(zipfile.entries.first.name).split(/[\r\n]+/).each do |line|
          yield(line)
        end
      end

      def parse_search_results(file)
        books = []
        Context.unzip_readlines(file) do |result|
          begin
            book_hash = Irc::Books::ResultsParser.create_hash(result)
            books << book_hash
          rescue Irc::Books::ResultParserError => e
            # @bot.loggers.warn("#{e} - #{result}")
          end
        end
        books
      end

      def setup_callbacks
        init_chooser_on_quit

        init_chooser_on_menu

        init_chooser_on_choice

        init_parse_search_bots_on_join
      end

      def on_next(wait_time = 1)
        @bot.Timer(wait_time, shots: 1) do
          yield
        end
      end

      def send_text_to_channel(channel, text)
        on_next do
          sanitized = Sanitize(text)
          @bot.loggers.info "sending text to channel: #{sanitized}"
          Channel(channel).send(sanitized)
        end
      end

      def ask_nickname
        @chooser.ask_nickname do |nickname|
          @search_model.nickname = nickname
        end
      end

      def configure_bot
        @bot.configure do |conf|
          conf.server = Context::IRC_HIGHWAY_URL
          conf.channels = [Context::EBOOKS]
          conf.nick = @search_model.nickname
        end
      end

      def start
        setup_callbacks

        ask_nickname unless @search_model.nickname

        configure_bot

        @bot.start
      end
    end
  end
end
