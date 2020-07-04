# frozen_string_literal: true

require 'irc/books/book'

module Irc
  module Books
    # parse incoming irc msgs for meaningful values
    class ResultsParser
      LABEL_REGEX = /^(.*) [\[\(](.*)[\)\]]$/.freeze
      BOOK_VERSION = ['v5.0', 'retail'].freeze
      BOOK_FORMAT = %i[epub mobi].freeze
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

      def self.create_hash_from_match(parser, match)
        match_array = match.to_a

        book_hash = {
          series: nil,
          series_number: 0
        }

        match_array[parser[:author]] = ResultsParser.parse_author(match_array[parser[:author]])
        parser.each do |key, val|
          next if %i[regex name].include?(key)

          book_hash[key] = match_array[val]
        end

        title, book_version, book_format, labels = parse_title_labels(book_hash[:title], book_hash[:author], book_hash[:downloaded_format])
        book_hash[:title] = title
        book_hash[:book_version] = book_version
        book_hash[:book_format] = book_format
        book_hash[:labels] = labels

        book_hash
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

      def self.create_book(result)
        book_hash = ResultsParser.create_hash(result)
        # puts book_hash
        Book.new(book_hash)
      end

      def self.match_regex(result)
        PARSERS.each do |parser|
          result.match(parser[:regex]) do |match|
            return parser, match
          end
        end
        raise "Error - No Parser could parse: #{result}"
      end

      def self.parse_title_labels(title, _author, downloaded_format)
        labels = []
        book_format = :unknown
        book_version = :unknown

        loop do
          found_match = false

          title.match(LABEL_REGEX) do |match|
            title = match[1]
            label = match[2]
            # book_version_match = label.match(BookVersionRegex)
            if BOOK_VERSION.include?(label)
              book_version = label
              # book_version = Integer(book_version_match[1])
            elsif BOOK_FORMAT.include?(label.to_sym)
              book_format = label.to_sym
            else
              labels << label
            end

            found_match = true
            title.strip!
          end
          break unless found_match == true
        end

        if BOOK_FORMAT.include?(downloaded_format.to_sym)
          book_format = downloaded_format.to_sym if book_format == :unknown
        end

        [title, book_version, book_format, labels]
      end

      def self.create_hash(result)
        parser, match = match_regex(result)

        create_hash_from_match(parser, match)
      end
    end
  end
end
