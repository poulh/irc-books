# frozen_string_literal: true

require 'irc/books/book'

module Irc
  module Books
    # groups books by author, series, and prunes to retail editions if possible
    class BookSorter
      DEFAULT_GROUP_BY = %i[author series series_number title].freeze
      def self.display_each_book(books)
        book_groups = group_books_by(books, DEFAULT_GROUP_BY)
        sort_book_groups!(book_groups)

        book_keys = book_groups.keys.sort # { |a, b| a[:display] <=> b[:display] }
        book_keys.each do |book_key|
          books_in_group = book_groups[book_key]
          top_book = books_in_group[0]
          yield("#{book_key} ---> #{top_book[:line]}", top_book)
        end
      end

      def self.sort_book_groups!(book_groups)
        book_groups.each do |_book_key, books|
          books.sort! { |a, b| book_version_sort(b) <=> book_version_sort(a) }
        end
      end

      def self.group_books_by(books, _by)
        groups = Hash.new { |hash, key| hash[key] = [] }

        books.each do |book|
          book_key = book_display_name(book)

          groups[book_key] << book
        end
        groups
      end

      def self.sort_and_uniq_book_versions(_books)
        books.sort! { |a, b| book_version_sort(b) <=> book_version_sort(a) }
        books.uniq! { |b| book_version_sort(b) }

        books
      end

      def self.book_version_sort(book)
        bv = book[:version] || 'v0.0'
        bv = 'v6.0' if bv.downcase == 'retail'
        bv
      end

      def self.book_display_name(book)
        series = ''
        if book[:series]
          series_num = book[:series_number] || '?'
          series = "#{book[:series]} (#{series_num}) - "
        end
        "#{book[:author]} <-> #{series} <-> #{book[:title]} <-> #{book[:version]}"
      end
    end
  end
end
