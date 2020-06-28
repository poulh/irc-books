module Irc
  module Books
    # parse incoming irc msgs for meaningful values
    module ResultsParser
      class BookParser
        REGEX = /^!(\S*) (.*) - (.*)\.(\S+)\s+::INFO::\s+(.\S)/
        SOURCE = 0
        AUTHOR = 1
        TITLE = 2
        DOWNLOAD_FORMAT = 3
        SIZE = 4
      end

      BookRegex = /^!(\S*) (.*) - (.*)\.(\S+)\s+::INFO::\s+(\S+)/
      SeriesBookRegex = /^!(\S*) (.*) - \[?(.*) (\d+)\]? - (.*)\.(\S+)\s+::INFO::\s+(\S+)/
      LabelRegex = /^(.*) [\[\(](.*)[\)\]]$/

      BOOK_FORMAT = [:epub, :mobi]

      BookVersionRegex = /v(\d).\d/
      BOOK_VERSION = ["v5.0", "retail"]

      class Book
        attr_accessor :line, :source, :series, :author,
                      :series_number, :title,
                      :downloaded_format, :size, :book_version,
                      :book_format, :labels

        def initialize(line, source, author, title, downloaded_format, size)
          title, book_version, book_format, labels = parse_title_labels(title, author, downloaded_format)

          @line = line
          @source = source
          @title = title
          @author = author

          @series = nil
          @series_number = 0
          @downloaded_format = downloaded_format
          @size = size
          @book_version = book_version
          @book_format = book_format
          @labels = labels
        end

        def parse_title_labels(title, author, downloaded_format)
          labels = []
          book_format = :unknown
          book_version = :unknown

          loop do
            found_match = false

            title.match(LabelRegex) do |match|
              title = match[1]
              label = match[2]
              # book_version_match = label.match(BookVersionRegex)
              if BOOK_VERSION.include?(label)
                book_version = label
                #book_version = Integer(book_version_match[1])
              elsif BOOK_FORMAT.include?(label.to_sym)
                book_format = label.to_sym
              else
                labels << label
              end

              if BOOK_FORMAT.include?(downloaded_format.to_sym)
                book_format = downloaded_format.to_sym if book_format == :unknown
              end

              found_match = true
              title.strip!
            end
            break unless found_match == true
          end

          return title, book_version, book_format, labels
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

      class SeriesBook < Book
        def initialize(line, source, author, series, series_number, title, downloaded_as, size)
          super(line, source, author, title, downloaded_as, size)
          self.series = series
          self.series_number = series_number
        end
      end

      def self.parse_author(author)
        last, first = author.split(", ")
        if first
          author = "#{first} #{last}"
          # else

          #   author = last unless first
        end

        parts = []
        author.split(" ").each do |part|
          parts << part.strip
        end

        author = parts.join(" ")
        author.strip
      end

      def self.parse(result, parser)
        result.match(parser.REGEX) do |match|
          match_array = match.to_a
          author = match_array[parser.AUTHOR]
          match_array[parser.AUTHOR] = parse_author(author)
          b = SeriesBook.new(*match_array)
        end
      end

      def self.parse_result(result)
        result.match(SeriesBookRegex) do |match|
          match_array = match.to_a
          match_array[2] = parse_author(match_array[2])

          b = SeriesBook.new(*match_array)
          return b
        end

        result.match(BookRegex) do |match|
          match_array = match.to_a
          match_array[2] = parse_author(match_array[2])

          b = Book.new(*match_array)
          return b
        end

        return nil
      end
    end
  end
end
