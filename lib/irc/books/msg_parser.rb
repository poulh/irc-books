# frozen_string_literal: true

# class for choosing menus

module Irc
  module Books
    # parse incoming irc msgs for meaningful values
    module MsgParser
      SEARCH_BOT_REGEX = '@.*'
      def self.parse_search_bots_from_topic(msg)
        search_bots = msg.channel.topic.strip.split.select { |word| word.match(/@.*/) }
        search_bots.collect { |botnames| botnames.delete('@').downcase }
      end
    end
  end
end
