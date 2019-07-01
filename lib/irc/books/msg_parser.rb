# frozen_string_literal: true

# class for choosing menus

module Irc
  module Books
    # parse incoming irc msgs for meaningful values
    module MsgParser
      SEARCH_BOT_REGEX = '@.*'
      def self.parse_search_bots_from_topic(msg)
        words = msg.channel.topic.strip.split
        search_bots = words.select { |word| word.match(/#{SEARCH_BOT_REGEX}/) }
        search_bots.collect { |botnames| botnames.delete('@').downcase }
      end
    end
  end
end
