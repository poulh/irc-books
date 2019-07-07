# frozen_string_literal: true

require 'cinch'
require 'cinch/helpers'

require 'irc/books/chooser'
require 'irc/books/msg_parser'
require 'irc/books/search_model'

# main class of application

module Irc
  module Books
    class Context
      include Cinch::Helpers

      attr_accessor :model, :chooser
      EBOOKS = '#ebooks'
      IRC_HIGHWAY_URL = 'irc.irchighway.net'

      def main_menu
        on_next do
          @chooser.choose
        end
      end

      def initialize
        @bot = Cinch::Bot.new
        @bot.loggers.level = :fatal # :error

        @model = Irc::Books::SearchModel.new
        @chooser = Irc::Books::Chooser.new(@model)
      end

      def init_chooser_on_quit
        @chooser.on :quit do
          @bot.quit
          sleep(2)
          exit
        end
      end

      def init_chooser_on_choice
        @chooser.on :choice do |choice|
          case choice[:command]
          when Irc::Books::Chooser::SEARCH

            search, status = @model.add_search(choice[:phrase])

            next unless status

            cmd = "@#{search[:bot]} #{search[:phrase]}"
            send_text_to_channel(EBOOKS, cmd)
          else
            puts "unknown command #{choice}"
          end
        end
      end

      def init_bot_on_join
        @bot.on :join, //, self do |msg, ctxt|
          next unless Irc::Books::MsgParser.bot_nick_msg?(@bot, msg)

          ctxt.model.search_bots = Irc::Books::MsgParser.parse_search_bots_from_topic(msg)
          ctxt.main_menu
        end
      end

      def init_bot_on_accept_search_results_file
        @bot.on :dcc_send, //, self do |msg, dcc, _ctxt|
          user = msg.user.nick.downcase
          begin
            filename = dcc.filename
            file = Tempfile.new(filename)
            dcc.accept(file)
            file.close
            @chooser.accept_file(user, filename, file)
          end
        end
      end

      def init_bot_on_search_acknowledged
        @bot.on :private, //, self do |msg, _dcc, _ctxt|
          next unless Irc::Books::MsgParser.bot_nick_msg?(@bot, msg)

          search_status = Irc::Books::MsgParser.parse_search_status_msg(msg)
          search, status = search_model.update_search_status(search_status)
          if status
            @chooser.notify_search_in_progress(search)
          else
            @chooser.notify_no_search_results(search)
          end
        end
      end

      def setup_callbacks
        init_chooser_on_quit

        init_chooser_on_choice

        # @bot.on :connect do |_msg|
        #   nil
        # end

        init_bot_on_join

        init_bot_on_search_acknowledged

        init_bot_on_accept_search_results_file

        # @bot.on :message do |_msg|
        #   nil
        # end
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

      def start
        setup_callbacks

        @chooser.ask_nickname do |nickname|
          @model.nickname = nickname
        end

        @bot.configure do |conf|
          conf.server = IRC_HIGHWAY_URL
          conf.channels = [EBOOKS]
          conf.nick = @model.nickname
        end

        @bot.start
      end
    end
  end
end
