# frozen_string_literal: true

module Irc
  module Books
    # For Context Menus that you want to repeat after a choice.
    # Loops and prints menu until go-back choice selected
    class MenuLoop
      def initialize
        @loop_end = false

        loop do
          begin
            yield(self)
          rescue StandardError => e
            puts "caught error: #{e}\n#{e.backtrace}"

            @loop_end = true
          end
          break if @loop_end == true
        end
      end

      def go_back
        @loop_end = true
      end

      def go_back_choice(menu, phrase)
        menu.choice(phrase) do
          go_back
        end
        menu.default = phrase
      end

      def refresh_choice(menu, phrase = 'Refresh')
        menu.choice(phrase) do
        end
      end
    end
  end
end
