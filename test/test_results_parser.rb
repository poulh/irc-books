# frozen_string_literal: true

require 'minitest/autorun'
require 'irc/books/results_parser'

class ResultParserTest < Minitest::Test
  def test_book_source_author_title_bookfmt_downloadfmt_size
    line = '!Ook Alex Berenson - The Prince of Beers (epub).rar ::INFO:: 89.36KB'
    book = Irc::Books::ResultsParser.create_book(line)

    assert_equal 'Ook', book.source
    assert_equal 'Alex Berenson', book.author
    assert_equal 'The Prince of Beers', book.title
    assert_equal :epub, book.book_format
    assert_nil book.series
    assert_equal 0, book.series_number
    assert_equal :unknown, book.book_version
    assert_equal 'rar', book.downloaded_format
    assert_equal '89.36KB', book.size
  end

  def test_series_retail
    line = '!JimBob420 Alex Berenson - [John Wells 09] - Twelve Days (retail) (epub).rar ::INFO:: 1.01MB'
    book = Irc::Books::ResultsParser.create_book(line)

    assert_equal 'JimBob420', book.source
    assert_equal 'Alex Berenson', book.author
    assert_equal 'Twelve Days', book.title
    assert_equal :epub, book.book_format
    assert_equal 'John Wells', book.series
    assert_equal 9, book.series_number
    assert_equal 'retail', book.book_version
    assert_equal 'rar', book.downloaded_format
    assert_equal '1.01MB', book.size
  end

  def test_epub_as_extension
    # two spaces before ::INFO:: intentional
    line = '!dragnbreaker Berenson, Alex - John Wells 04 - The Midnight House (v5.0).epub  ::INFO:: 561.8KB'

    book = Irc::Books::ResultsParser.create_book(line)

    assert_equal 'dragnbreaker', book.source
    assert_equal 'Alex Berenson', book.author
    assert_equal 'The Midnight House', book.title
    assert_equal :epub, book.book_format
    assert_equal 'John Wells', book.series
    assert_equal 4, book.series_number
    assert_equal 'v5.0', book.book_version
    assert_equal 'epub', book.downloaded_format
    assert_equal '561.8KB', book.size
  end

  def test_epub_as_extension_hash
    # two spaces before ::INFO:: intentional
    line = '!dragnbreaker Berenson, Alex - John Wells 04 - The Midnight House (v5.0).epub  ::INFO:: 561.8KB'

    book_hash = Irc::Books::ResultsParser.create_hash(line)

    assert_equal 'dragnbreaker', book_hash[:source]
    assert_equal 'Alex Berenson', book_hash[:author]
    assert_equal 'The Midnight House', book_hash[:title]
    assert_equal :epub, book_hash[:book_format]
    assert_equal 'John Wells', book_hash[:series]
    assert_equal '04', book_hash[:series_number]
    assert_equal 'v5.0', book_hash[:book_version]
    assert_equal 'epub', book_hash[:downloaded_format]
    assert_equal '561.8KB', book_hash[:size]
  end

  def test_3
    line = '!DukeLupus Berenson, Alex - John Wells 02 - The Ghost War - Berenson, Alex.epub ::INFO:: 518.61KB'

    book = Irc::Books::ResultsParser.create_book(line)

    assert_equal 'DukeLupus', book.source
    assert_equal 'Alex Berenson', book.author
    assert_equal 'The Ghost War - Berenson, Alex', book.title
    assert_equal :epub, book.book_format
    assert_equal 'John Wells', book.series
    assert_equal 2, book.series_number
    assert_equal :unknown, book.book_version
    assert_equal 'epub', book.downloaded_format
    assert_equal '518.61KB', book.size
  end

  def test_parse_author
    assert_equal 'Jim Smith', Irc::Books::ResultsParser.parse_author('Smith, Jim')
    assert_equal 'Jim Smith', Irc::Books::ResultsParser.parse_author('Smith,  Jim')
    assert_equal 'Jim Smith', Irc::Books::ResultsParser.parse_author(' Smith,  Jim')
    assert_equal 'Jim Smith', Irc::Books::ResultsParser.parse_author('Smith, Jim ')

    assert_equal 'Jim Smith', Irc::Books::ResultsParser.parse_author('Jim Smith')
    assert_equal 'Jim Smith', Irc::Books::ResultsParser.parse_author('Jim Smith ')
    assert_equal 'Jim Smith', Irc::Books::ResultsParser.parse_author(' Jim Smith ')

    assert_equal 'Jim Middlename Smith', Irc::Books::ResultsParser.parse_author('Jim Middlename Smith')
    assert_equal 'Jim Middlename Smith', Irc::Books::ResultsParser.parse_author('Smith, Jim Middlename')
  end
end
