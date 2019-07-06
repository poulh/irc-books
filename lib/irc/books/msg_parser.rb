# frozen_string_literal: true

# class for choosing menus

module Irc
  module Books
    # parse incoming irc msgs for meaningful values
    module MsgParser
      def self.bot_nick_msg?(bot, msg)
        bot.nick.downcase == msg.user.nick.downcase
      end

      SEARCH_BOT_REGEX = '@.*'
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

        sanitized = Sanitize(msg.message)
        search_in_progress = !sanitized.index(NO_RESULTS_REGEX)

        { bot: bot, phrase: sanitized, in_progress: search_in_progress }
      end
    end
  end
end
