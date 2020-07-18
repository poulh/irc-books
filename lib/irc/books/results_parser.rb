# frozen_string_literal: true

require 'irc/books/book'

module Irc
  module Books
    class ResultParserError < StandardError
    end
    # parse incoming irc msgs for meaningful values
    class ResultsParser
      LABEL_REGEX_OLD = /^(.*) [\[\(](.*)[\)\]]$/.freeze
      LABEL_REGEX = /(.*)[\[\(](.*)[\)\]]/.freeze
      BOOK_VERSION = ['v5.0', 'v4.0', 'retail'].freeze
      NUMBER_OPTIONAL_DECIMAL_REGEX = /\d+(\.\d+)?/.freeze
      SERIES_REGEX = /\[?([a-zA-Z\s&]+)\s?(\d+(\.\d+)?)?\]?/.freeze
      PHRASE_SERIES_REGEX = /(.*)\[([a-zA-Z\s&]+)\s?(\d+(\.\d+)?)\]/.freeze # \d+\.?\d*
      BOOK_FORMAT = %w[epub mobi].freeze
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

      # --------------------------
      def self.create_bh
        {
          line: '', source: '', author: '', title: '',
          book_format: '', series: nil, series_number: nil,
          book_version: nil, downloaded_format: '', size: nil,
          filename: '', labels: []
        }
      end

      def self.match_or_throw(phrase, hint, reg)
        match = phrase.match(reg)
        raise ResultParserError, "cannot parse #{hint}: #{phrase}" unless match

        match_array = match.to_a.collect { |m| m&.strip }
        match_array = match_array.collect { |m| m&.empty? ? nil : m }
        match_array
      end

      def self.delete_special_labels(special_values, labels)
        special_value = nil
        special_values.each do |special|
          idx = labels.find_index { |i| i.downcase == special.downcase }
          unless idx.nil?

            labels.delete_at(idx)
            special_value = special
          end

          break if special_value
        end
        [labels, special_value]
      end

      def self.parse_labels_off_phrase(phrase)
        labels = []
        loop do
          begin
            _orig, phrase, label = match_or_throw(phrase, :labels, LABEL_REGEX)
            label = label.split(',').collect(&:strip)
            labels += label
          rescue StandardError => _e
            break
          end
        end
        [phrase, labels]
      end

      def self.create_hash(result)
        book_hash = create_bh
        book_hash[:line], book_hash[:source], remainder = match_or_throw(result, :source, /^!(\S*)\s+(.*)/)

        remainder, book_hash[:size] = remainder.split('::INFO::').collect(&:strip)
        book_hash[:filename] = remainder

        parts = remainder.split(' - ').collect(&:strip)
        _orig, parts[-1], book_hash[:downloaded_format] = match_or_throw(parts[-1], :downloaded_format, /(.*)\.(.*)/)

        parts[-1], labels = parse_labels_off_phrase(parts[-1])

        labels, book_hash[:book_version] = delete_special_labels(BOOK_VERSION, labels)
        labels, book_hash[:book_format] = delete_special_labels(BOOK_FORMAT, labels)
        unless book_hash[:book_format]
          book_hash[:book_format] = book_hash[:downloaded_format]
        end
        book_hash[:labels] = labels

        parts.pop if parts[0] == parts[-1]

        if parts.size > 2
          series_name_number = parts.delete_at(1)
          _orig, book_hash[:series], book_hash[:series_number] = match_or_throw(series_name_number, :series, SERIES_REGEX)
          # parts.pop if parts.size > 2
        else
          begin
            _orig, parts[0], book_hash[:series], book_hash[:series_number] = match_or_throw(parts[0], :series, PHRASE_SERIES_REGEX)
          rescue StandardError => e
          end

        end

        book_hash[:author] = parse_author(parts[0])
        book_hash[:title] = parts[1]

        book_hash
      end
    end
  end
end
