# frozen_string_literal: true

require 'cinch/helpers'

# class for choosing menus

module Irc
  module Books
    # parse incoming irc msgs for meaningful values
    module MsgParser
      def self.bot_nick_msg?(bot, msg)
        msg_user = msg.user
        bot_nick = bot.nick
        return false unless bot_nick
        return false unless msg_user

        bot_nick.downcase == msg_user.nick.downcase
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
        bot = msg.user.nick.downcase

        sanitized = Cinch::Helpers.sanitize(msg.message)
        status = sanitized.index(NO_RESULTS_REGEX) ? :no_results : :in_progress

        [{ bot: bot, phrase: sanitized }, status]
      end
    end
  end
end
