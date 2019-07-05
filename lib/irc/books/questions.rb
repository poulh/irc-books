# frozen_string_literal: true

require 'irc/books/search_model'
# class for choosing menus

module Irc
  module Books
    module Question
      def self.nickname
        question = HighLine::Question.new('What is your nickname?', String)
        question.validate = ->(answer) { (4..12).cover?(answer.length) }
        question.responses[:not_valid] = 'Nickname length must be between 4 and 12 characters'
        question
      end

      def self.download_path
        question = HighLine::Question.new('What would you like the download path to be?', String)
        question.validate = ->(answer) { File.directory?(File::expand_path(answer)) }
        question.responses[:not_valid] = 'You must enter a valid directory path'
        question
      end
    end
  end
end
