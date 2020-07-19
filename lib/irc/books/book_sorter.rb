# frozen_string_literal: true

require 'irc/books/book'

module Irc
  module Books
    # groups books by author, series, and prunes to retail editions if possible
    class BookSorter
      DEFAULT_GROUP_BY = %i[country author series series_number title].freeze
      def self.display_each_book(books)
        books.each do |book|
          book[:series_number] = parse_book_series_number(book[:series_number])
        end

        book_groups = group_books_by(books, DEFAULT_GROUP_BY)
        sort_book_groups!(book_groups)

        book_keys = book_groups.keys.sort
        book_keys.each do |book_key|
          books_in_group = book_groups[book_key]
          top_book = books_in_group[0]
          display_book = book_display_name(top_book) # this is the book key, just not downcased
          yield("#{display_book} ---> #{top_book[:book_version]} ---> #{top_book[:line]}", top_book)
        end
      end

      def self.parse_book_series_number(series_number_string)
        series_number = nil
        begin
          series_number = Float(series_number_string).to_s.rjust(6, '0')
        rescue StandardError => _e
          series_number = nil
        end

        series_number
      end

      def self.sort_book_groups!(book_groups)
        book_groups.each do |_book_key, books|
          books.sort! { |a, b| book_version_sort(b) <=> book_version_sort(a) }
        end
      end

      def self.group_books_by(books, _by)
        groups = Hash.new { |hash, key| hash[key] = [] }

        books.each do |book|
          book_key = book_display_name(book).downcase

          groups[book_key] << book
        end
        groups
      end

      def self.sort_and_uniq_book_versions(books)
        books.sort! { |a, b| book_version_sort(b) <=> book_version_sort(a) }
        books.uniq! { |b| book_version_sort(b) }

        books
      end

      def self.book_version_sort(book)
        bv = book[:book_version] || 'v0.0'
        bv = 'v6.0' if bv.downcase == 'retail'
        bv
      end

      def self.book_display_name(book)
        series = ''
        if book[:series]
          series_num = book[:series_number] || '?'
          series = "#{book[:series]} (#{series_num}) - "
        end
        "#{book[:country]} <-> #{book[:author]} <-> #{series} <-> #{book[:title]}"
      end
    end
  end
end
