# frozen_string_literal: true

require 'cinch/helpers'

# class for choosing menus

module Irc
  module Books
    # parse incoming irc msgs for meaningful values
    module MsgParser
      def self.msg_user(msg)
        msg_user = msg.user
        return unless msg_user

        msg_user.nick.downcase
      end

      def self.bot_nick_msg?(bot, msg)
        bot_nick = bot.nick
        return false unless bot_nick

        bot_nick.downcase == MsgParser.msg_user(msg)
      end

      SEARCH_BOT_REGEX = '@.*[Ss]earch.*'
      BOT_NAME_PREFIX = '@'
      def self.parse_search_bots_from_topic(msg)
        words = msg.channel.topic.strip.split
        search_bots = words.select { |word| word.match(/#{SEARCH_BOT_REGEX}/) }
        search_bots.collect do |botnames|
          botnames.delete(BOT_NAME_PREFIX).downcase
        end
      end

      NO_RESULTS_REGEX = 'Sorry'
      def self.parse_search_status_msg(msg)
        bot = MsgParser.msg_user(msg)
        return [nil, {}] unless bot

        sanitized = Cinch::Helpers.sanitize(msg.message)
        status = sanitized.index(NO_RESULTS_REGEX) ? :no_results : :in_progress

        [bot, { search_bot: bot, phrase: sanitized, status: status }]
      end

      def self.accept_file(filename, dcc)
        file = Tempfile.new(filename)
        dcc.accept(file)
        file.close
        file
      end

      def self.parse_user_and_accept_file(msg, dcc)
        sender = MsgParser.msg_user(msg)
        filename = dcc.filename
        file = MsgParser.accept_file(filename, dcc)

        [sender, filename, file]
      end
    end
  end
end
