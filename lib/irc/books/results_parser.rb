# frozen_string_literal: true

require 'irc/books/book'

module Irc
  module Books
    # parse incoming irc msgs for meaningful values
    class ResultsParser
      PARSERS = [
        {
          name: 'Series Book Parser',
          regex: /^!(\S*) (.*) - \[?(.*) (\d+)\]? - (.*)\.(\S+)\s+::INFO::\s+(.*)/,
          line: 0,
          source: 1,
          author: 2,
          series: 3,
          series_number: 4,
          title: 5,
          downloaded_format: 6,
          size: 7
        },
        {
          name: 'Book Parser',
          regex: /^!(\S*) (.*) - (.*)\.(\S+)\s+::INFO::\s+(.*)/,
          line: 0,
          source: 1,
          author: 2,
          title: 3,
          downloaded_format: 4,
          size: 5
        }
      ].freeze

      def self.create(parser, match_array)
        params = {
          series: nil,
          series_number: 0
        }

        match_array[parser[:author]] = ResultsParser.parse_author(match_array[parser[:author]])
        parser.each do |key, val|
          next if %i[regex name].include?(key)

          params[key] = match_array[val]
        end
        Book.new(params)
      end

      def self.parse_author(author)
        last, first = author.split(', ')
        author = "#{first} #{last}" if first

        parts = []
        author.split(' ').each do |part|
          parts << part.strip
        end

        author = parts.join(' ')
        author.strip
      end

      def self.parse_result(result)
        PARSERS.each do |parser|
          result.match(parser[:regex]) do |match|
            match_array = match.to_a
            return ResultsParser.create(parser, match_array)
          end
        end
      end
    end
  end
end
