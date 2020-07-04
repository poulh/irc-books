# frozen_string_literal: true

require 'minitest/autorun'
require 'irc/books/results_parser'

class ResultParserTest < Minitest::Test
  def setup
    @books = [
      {
        line: '!Ook Alex Berenson - The Prince of Beers (epub).rar ::INFO:: 89.36KB',
        source: 'Ook',
        author: 'Alex Berenson',
        title: 'The Prince of Beers',
        book_format: 'epub',
        series: nil,
        series_number: nil,
        book_version: nil,
        downloaded_format: 'rar',
        size: '89.36KB'
      },
      {
        line: '!JimBob420 Alex Berenson - [John Wells 09] - Twelve Days (retail) (epub).rar ::INFO:: 1.01MB',
        source: 'JimBob420',
        author: 'Alex Berenson',
        title: 'Twelve Days',
        book_format: 'epub',
        series: 'John Wells',
        series_number: '09',
        book_version: 'retail',
        downloaded_format: 'rar',
        size: '1.01MB'
      },
      {
        line: '!dragnbreaker Berenson, Alex - John Wells 04 - The Midnight House (v5.0).epub  ::INFO:: 561.8KB',
        source: 'dragnbreaker',
        author: 'Alex Berenson',
        title: 'The Midnight House',
        book_format: 'epub',
        series: 'John Wells',
        series_number: '04',
        book_version: 'v5.0',
        downloaded_format: 'epub',
        size: '561.8KB'
      },
      {
        line: '!DukeLupus Berenson, Alex - John Wells 02 - The Ghost War - Berenson, Alex.epub ::INFO:: 518.61KB',
        source: 'DukeLupus',
        author: 'Alex Berenson',
        title: 'The Ghost War',
        book_format: 'epub',
        series: 'John Wells',
        series_number: '02',
        book_version: nil,
        downloaded_format: 'epub',
        size: '518.61KB'
      },
      {
        line: '!Xon Deliver Us from Evil - David Baldacci(epub).rar',
        source: 'Xon',
        author: 'Deliver Us from Evil',
        title: 'David Baldacci',
        book_format: 'epub',
        series: nil,
        series_number: nil,
        book_version: nil,
        downloaded_format: 'rar',
        size: nil
      }, {
        line: '!Xon David Baldacci - [Camel Club 03] - Stone Cold (v5.0) (epub).rar',
        source: 'Xon',
        author: 'David Baldacci',
        title: 'Stone Cold',
        book_format: 'epub',
        series: 'Camel Club',
        series_number: '03',
        book_version: 'v5.0',
        downloaded_format: 'rar',
        size: nil
      }, {
        line: '!TrainFiles David Baldacci - [Atlee Pine 02] - A Minute to Midnight  (retail) (epub).rar',
        source: 'TrainFiles',
        author: 'David Baldacci',
        title: 'A Minute to Midnight',
        book_format: 'epub',
        series: 'Atlee Pine',
        series_number: '02',
        book_version: 'retail',
        downloaded_format: 'rar',
        size: nil
      }, {
        line: '!Oatmeal David Baldacci - [Amos Decker 06] - Walk the Wire (US) (epub).rar  ::INFO:: 698.2KB',
        source: 'Oatmeal',
        author: 'David Baldacci',
        title: 'Walk the Wire',
        book_format: 'epub',
        series: 'Amos Decker',
        series_number: '06',
        book_version: nil,
        downloaded_format: 'rar',
        size: '698.2KB',
        labels: ['US']
      }, {
        line: '!Oatmeal The Collectors - David Baldacci.epub  ::INFO:: 422.1KB',
        source: 'Oatmeal',
        author: 'The Collectors',
        title: 'David Baldacci',
        book_format: 'epub',
        series: nil,
        series_number: nil,
        book_version: nil,
        downloaded_format: 'epub',
        size: '422.1KB'
      },
      {
        line: '!LawdyServer Baldacci, David - No Time Left - Baldacci, David.epub  ::INFO:: 174.9KB',
        source: 'LawdyServer',
        author: 'David Baldacci',
        title: 'No Time Left',
        book_format: 'epub',
        series: nil,
        series_number: nil,
        book_version: nil,
        downloaded_format: 'epub',
        size: '174.9KB'
      },
      {
        line: '!Oatmeal David Baldacci - Freddy and the French Fries - The Mystery of Silas Finklebean (epub).rar  ::INFO:: 1.9MB',
        source: 'Oatmeal',
        author: 'David Baldacci',
        title: 'The Mystery of Silas Finklebean',
        book_format: 'epub',
        series: 'Freddy and the French Fries',
        series_number: '',
        book_version: nil,
        downloaded_format: 'rar',
        size: '1.9MB'

      }

    ]
  end

  def test_books
    @books.each do |book|
      line = book[:line]

      test_book = Irc::Books::ResultsParser.create_hash(line)
      book.keys.each do |key|
        expected_val = book[key]
        fail_msg = [key, line].join(' - ')
        if expected_val
          assert_equal expected_val, test_book[key], fail_msg
        else
          assert_nil test_book[key], fail_msg
        end
      end
    end
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
