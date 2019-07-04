# frozen_string_literal: true

require 'irc/books/search_model'
# class for choosing menus

module Irc
  module Books
    module Question
      def self.nickname
        question = HighLine::Question.new('What is your nickname?', String)
        question.validate = ->(answer) { (answer.length >= 4) && (answer.length <= 12) }
        question.responses[:not_valid] = 'You must enter a nickname between 4 and 12 characters'
        question
      end
    end
  end
end
