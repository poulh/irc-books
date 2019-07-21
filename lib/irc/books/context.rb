# frozen_string_literal: true

require 'cinch'
require 'cinch/helpers'

require 'irc/books/chooser'
require 'irc/books/msg_parser'
require 'irc/books/search_model'

module Irc
  module Books
    # main class of application
    class Context
      attr_accessor :model, :chooser
      include Cinch::Helpers

      EBOOKS = '#ebooks'
      IRC_HIGHWAY_URL = 'irc.irchighway.net'

      def main_menu
        wait_time = 30
        puts "mandatory #{wait_time} second wait"
        on_next(wait_time) do
          @chooser.beep
          @chooser.choose
        end
      end

      def initialize(options)
        @bot = Cinch::Bot.new
        @bot.loggers.level = options[:log_level]

        @model = Irc::Books::SearchModel.new(options)
        @chooser = Irc::Books::Chooser.new(@model)
      end

      attr_reader :bot

      def init_chooser_on_quit
        @chooser.on :quit do
          @bot.quit
          sleep(10)
        end
      end

      def init_chooser_on_choice
        @chooser.on :choice do |choice|
          phrase = choice[:phrase]
          case choice[:command]
          when Irc::Books::Chooser::SEARCH

            search, status = @model.add_search(phrase)
            init_on_search(search)
            next if status == :error

            cmd = "@#{search[:search_bot]} #{search[:phrase]}"
            send_text_to_channel(EBOOKS, cmd)
          when Irc::Books::Chooser::DOWNLOAD
            send_text_to_channel(EBOOKS, phrase)
          else
            puts "unknown command #{choice}"
          end
        end
      end

      def init_parse_search_bots_on_join
        @bot.on :join, //, self do |msg, ctxt|
          next unless Irc::Books::MsgParser.bot_nick_msg?(@bot, msg)

          ctxt.model.search_bots = Irc::Books::MsgParser.parse_search_bots_from_topic(msg)

          ctxt.main_menu
        end
      end

      def notify_search_status(search)
        case search[:status]
        when :in_progress
          chooser.notify_search_in_progress(search)
        when :no_results
          chooser.notify_no_search_results_found(search)
        end
      end

      def init_on_search(search)
        init_on_search_accepted(search)
      end

      def init_on_search_accepted(search)
        regex_accepted = '^.*%{phrase}.*accepted.*$' % search
        @bot.loggers.info "registering: #{regex_accepted}"
        handler = @bot.on :private, /#{regex_accepted}/i, self do |_msg, context|
          context.init_on_search_results_found(search)
          context.chooser.notify_search_in_progress(search)
          context.bot.handlers.unregister(handler)
        end
      end

      def init_on_search_results_found(search)
        regex_results_found = '^.*%{phrase}.*returned \d+ match.*$' % search
        @bot.loggers.info "registering: #{regex_results_found}"
        # Your search for "12,9Tom Clancy epub1,9" returned 1000 match

        handler = @bot.on :private, /#{regex_results_found}/, self do |_msg, context|
          context.init_on_search_results_file_download(search)
          context.init_on_search_results_filename(search)
          context.bot.handlers.unregister(handler)
        end
      end

      def init_on_search_results_filename(search)
        puts search
        # two spaces on purpose after 'results for'
        regex_results_filename = '^.*results for  %{phrase}.*$' % search
        regex_results_filename.tr!(' ', '_')

        @bot.loggers.info "registering: #{regex_results_filename}"

        handler = @bot.on :private, /#{regex_results_filename}/, self do |_msg, context|
          context.chooser.beep
          context.bot.handlers.unregister(handler)
        end
      end

      def init_on_search_results_file_download(search)
        puts search
        # two spaces on purpose after 'results for'
        regex_results_file_download = '^.*results for  %{phrase}.*$' % search
        regex_results_file_download.tr!(' ', '_')

        @bot.loggers.info "registering: #{regex_results_file_download}"

        handler = @bot.on :dcc_send, /#{regex_results_file_download}/, self do |msg, context, dcc|
          _sender, filename, file = Irc::Books::MsgParser.parse_user_and_accept_file(msg, dcc)
          # search = ctxt.model.select_search(sender, phrase: filename)

          # if search
          new_path = File.join(context.model.download_path, filename)
          FileUtils.mv(file.path, new_path, verbose: true)
          context.model.downloads << new_path
          puts "New Download: #{new_path}"

          context.bot.handlers.unregister(handler)
        end
      end

      def setup_callbacks
        init_chooser_on_quit

        init_chooser_on_choice

        init_parse_search_bots_on_join

        @bot.on :message do |msg|
          # puts "msg: #{msg}"
        end
      end

      def on_next(wait = 1)
        @bot.Timer(wait, shots: 1) do
          yield
        end
      end

      def send_text_to_channel(channel, text)
        on_next do
          sanitized = Sanitize(text)
          Channel(channel).send(sanitized)
        end
      end

      def ask_nickname
        @chooser.ask_nickname do |nickname|
          @model.nickname = nickname
        end
      end

      def configure_bot
        @bot.configure do |conf|
          conf.server = Context::IRC_HIGHWAY_URL
          conf.channels = [Context::EBOOKS]
          conf.nick = @model.nickname
        end
      end

      def start
        setup_callbacks

        ask_nickname unless @model.nickname

        configure_bot

        @bot.start
      end
    end
  end
end
