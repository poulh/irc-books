# frozen_string_literal: true

module Irc
  module Books
    # parse incoming irc msgs for meaningful values
    module ResultsParser
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

      LABEL_REGEX = /^(.*) [\[\(](.*)[\)\]]$/.freeze

      BOOK_FORMAT = %i[epub mobi].freeze

      BOOK_VERSION_REGEX = /v(\d).\d/.freeze
      BOOK_VERSION = ['v5.0', 'retail'].freeze

      class Book
        attr_accessor :line, :source, :series, :author,
                      :series_number, :title,
                      :downloaded_format, :size, :book_version,
                      :book_format, :labels

        def initialize(line:, source:, author:, title:, downloaded_format:, size:, series:, series_number:)
          title, book_version, book_format, labels = parse_title_labels(title, author, downloaded_format)

          @line = line
          @source = source
          @title = title
          @author = author

          @series = series
          self.series_number = series_number

          @downloaded_format = downloaded_format
          @size = size
          @book_version = book_version
          @book_format = book_format
          @labels = labels
        end

        def parse_title_labels(title, _author, downloaded_format)
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

        def to_s
          <<~BOOKDOC
            Line: #{@line}
            Source: #{@source}
            Book Version: #{@book_version}
            Book Format: #{@book_format}
            Author: #{@author}
            Title: #{@title}
            Series: #{@series} (#{@series_number})
            Download Format: #{@downloaded_format}
            Size: #{@size}
            Labels: #{@labels}

          BOOKDOC
        end

        def series_number=(series_number)
          @series_number = series_number.to_i
        end
      end

      class BookFactory
        def create(parser, match_array)
          params = {
            series: nil,
            series_number: 0
          }

          match_array[parser[:author]] = BookFactory.parse_author(match_array[parser[:author]])
          parser.each do |key, val|
            next if key == :regex
            next if key == :name

            params[key] = match_array[val]
          end
          b = Book.new(params)
          b
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
      end

      def self.parse_result(result)
        PARSERS.each do |parser|
          result.match(parser[:regex]) do |match|
            bf = BookFactory.new
            match_array = match.to_a
            return bf.create(parser, match_array)
          end
        end
      end
    end
  end
end
