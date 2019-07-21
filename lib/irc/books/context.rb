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
      attr_accessor :model
      include Cinch::Helpers

      EBOOKS = '#ebooks'
      IRC_HIGHWAY_URL = 'irc.irchighway.net'

      def main_menu
        on_next do
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

      def init_on_accept_search_result_file_from_search_bot
        @bot.on :dcc_send, //, self do |msg, ctxt, dcc|
          sender, filename, file = Irc::Books::MsgParser.parse_user_and_accept_file(msg, dcc)
          search = ctxt.model.select_search(sender, phrase: filename)

          if search
            new_path = File.join(ctxt.model.download_path, filename)
            FileUtils.mv(file.path, new_path, verbose: true)
            ctxt.model.downloads << new_path
            puts "New Download: #{new_path}"
          else
            ctxt.chooser.accept_file(sender, filename, file)
          end
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

      def init_on_search_acknowledged_from_search_bot
        @bot.on :private, //, @model, @chooser do |msg, model, chooser|
          search_bot, search = Irc::Books::MsgParser.parse_search_status_msg(msg)
          next unless search_bot

          # begin
          existing_search = model.select_search(search_bot, search)
          existing_search[:status] = search[:status]
          updated_search = model.update_existing_search(existing_search)
          chooser.notify_search_results_found(updated_search)
          # rescue KeyError
          # chooser.notify_error_in_search_result(search)
          # end
        end
      end

      def setup_callbacks
        init_chooser_on_quit

        init_chooser_on_choice

        init_parse_search_bots_on_join
        init_on_search_acknowledged_from_search_bot
        init_on_accept_search_result_file_from_search_bot

        @bot.on :message do |msg|
          # puts "msg: #{msg}"
        end
      end

      def on_next
        @bot.Timer(1, shots: 1) do
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
