# frozen_string_literal: true

module Irc
  module Books
    # represents a book
    class Book
      LABEL_REGEX = /^(.*) [\[\(](.*)[\)\]]$/.freeze

      BOOK_FORMAT = %i[epub mobi].freeze

      BOOK_VERSION_REGEX = /v(\d).\d/.freeze
      BOOK_VERSION = ['v5.0', 'retail'].freeze

      attr_accessor :line, :source, :series, :author,
                    :title, :downloaded_format, :size,
                    :book_version, :book_format, :labels
      attr_reader :series_number

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
  end
end
