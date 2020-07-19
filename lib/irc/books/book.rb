# frozen_string_literal: true

module Irc
  module Books
    # represents a book
    class Book
      attr_accessor :line, :source, :series, :author,
                    :title, :downloaded_format, :size,
                    :book_version, :book_format, :labels, :country
      attr_reader :series_number

      def initialize(line:, source:, author:, title:, downloaded_format:, size:, series:, series_number:, book_version:, book_format:, labels:)
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

      def to_s
        <<~BOOKDOC
          Author: #{@author}
          Series: #{@series} (#{@series_number})
          Title: #{@title}
          Book Version: #{@book_version}
          Book Country: #{@book_country}
          Book Format: #{@book_format}
          Source: #{@source}
          Download Format: #{@downloaded_format}
          Size: #{@size}
          Labels: #{@labels}
          Line: #{@line}
        BOOKDOC
      end

      def series_number=(series_number)
        @series_number = series_number.to_i
      end
    end
  end
end
