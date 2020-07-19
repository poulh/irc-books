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
        filename: 'Alex Berenson - The Prince of Beers (epub).rar',
        downloaded_format: 'rar',
        size: '89.36KB',
        labels: [],
        country: nil
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
        filename: 'Alex Berenson - [John Wells 09] - Twelve Days (retail) (epub).rar',
        downloaded_format: 'rar',
        size: '1.01MB',
        labels: [],
        country: nil
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
        filename: 'Berenson, Alex - John Wells 04 - The Midnight House (v5.0).epub',
        downloaded_format: 'epub',
        size: '561.8KB',
        labels: [],
        country: nil
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
        filename: 'Berenson, Alex - John Wells 02 - The Ghost War - Berenson, Alex.epub',
        downloaded_format: 'epub',
        size: '518.61KB',
        labels: [],
        country: nil
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
        filename: 'Deliver Us from Evil - David Baldacci(epub).rar',
        downloaded_format: 'rar',
        size: nil,
        labels: [],
        country: nil
      }, {
        line: '!Xon David Baldacci - [Camel Club 03] - Stone Cold (v5.0) (epub).rar',
        source: 'Xon',
        author: 'David Baldacci',
        title: 'Stone Cold',
        book_format: 'epub',
        series: 'Camel Club',
        series_number: '03',
        book_version: 'v5.0',
        filename: 'David Baldacci - [Camel Club 03] - Stone Cold (v5.0) (epub).rar',
        downloaded_format: 'rar',
        size: nil,
        labels: [],
        country: nil
      }, {
        line: '!TrainFiles David Baldacci - [Atlee Pine 02] - A Minute to Midnight  (retail) (epub).rar',
        source: 'TrainFiles',
        author: 'David Baldacci',
        title: 'A Minute to Midnight',
        book_format: 'epub',
        series: 'Atlee Pine',
        series_number: '02',
        book_version: 'retail',
        filename: 'David Baldacci - [Atlee Pine 02] - A Minute to Midnight  (retail) (epub).rar',
        downloaded_format: 'rar',
        size: nil,
        labels: [],
        country: nil
      }, {
        line: '!Oatmeal David Baldacci - [Amos Decker 06] - Walk the Wire (US) (epub).rar  ::INFO:: 698.2KB',
        source: 'Oatmeal',
        author: 'David Baldacci',
        title: 'Walk the Wire',
        book_format: 'epub',
        series: 'Amos Decker',
        series_number: '06',
        book_version: nil,
        filename: 'David Baldacci - [Amos Decker 06] - Walk the Wire (US) (epub).rar',
        downloaded_format: 'rar',
        size: '698.2KB',
        labels: [],
        country: 'US'
      }, {
        line: '!Oatmeal The Collectors - David Baldacci.epub  ::INFO:: 422.1KB',
        source: 'Oatmeal',
        author: 'The Collectors',
        title: 'David Baldacci',
        book_format: 'epub',
        series: nil,
        series_number: nil,
        book_version: nil,
        filename: 'The Collectors - David Baldacci.epub',
        downloaded_format: 'epub',
        size: '422.1KB',
        labels: [],
        country: nil
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
        filename: 'Baldacci, David - No Time Left - Baldacci, David.epub',
        downloaded_format: 'epub',
        size: '174.9KB',
        labels: [],
        country: nil
      },
      {
        line: '!Oatmeal David Baldacci - Freddy and the French Fries - The Mystery of Silas Finklebean (epub).rar  ::INFO:: 1.9MB',
        source: 'Oatmeal',
        author: 'David Baldacci',
        title: 'The Mystery of Silas Finklebean',
        book_format: 'epub',
        series: 'Freddy and the French Fries',
        series_number: nil,
        book_version: nil,
        filename: 'David Baldacci - Freddy and the French Fries - The Mystery of Silas Finklebean (epub).rar',
        downloaded_format: 'rar',
        size: '1.9MB',
        labels: [],
        country: nil
      },
      {
        line: '!Oatmeal David Baldacci - [Sean King & Michelle Maxwell 01] - Split Second (v4.0) (epub, prc).rar  ::INFO:: 871.8KB',
        source: 'Oatmeal',
        author: 'David Baldacci',
        title: 'Split Second',
        book_format: 'epub',
        series: 'Sean King & Michelle Maxwell',
        series_number: '01',
        book_version: 'v4.0',
        filename: 'David Baldacci - [Sean King & Michelle Maxwell 01] - Split Second (v4.0) (epub, prc).rar',
        downloaded_format: 'rar',
        size: '871.8KB',
        labels: ['prc'],
        country: nil
      },
      {
        line: '!MusicWench David Baldacci [Camel Club 04] - Divine Justice [Epub].rar  ::INFO:: 376.2KB',
        source: 'MusicWench',
        author: 'David Baldacci',
        title: 'Divine Justice',
        book_format: 'epub',
        series: 'Camel Club',
        series_number: '04',
        book_version: nil,
        filename: 'David Baldacci [Camel Club 04] - Divine Justice [Epub].rar',
        downloaded_format: 'rar',
        size: '376.2KB',
        labels: [],
        country: nil
      },
      {
        line: '!dragnbreaker Grippando, James - Jack Swyteck 13.5 - Operation Northwoods (retail).epub  ::INFO:: 276.9KB',
        source: 'dragnbreaker',
        author: 'James Grippando',
        title: 'Operation Northwoods',
        book_format: 'epub',
        series: 'Jack Swyteck',
        series_number: '13.5',
        book_version: 'retail',
        filename: 'Grippando, James - Jack Swyteck 13.5 - Operation Northwoods (retail).epub',
        downloaded_format: 'epub',
        size: '276.9KB',
        labels: [],
        country: nil
      },
      {
        line: '!DV8 David Baldacci - Bullseye ( (EPUB).rar ::INFO:: 228.2KB',
        source: 'DV8',
        author: 'David Baldacci',
        title: 'Bullseye',
        book_format: 'epub',
        series: nil,
        series_number: nil,
        book_version: nil,
        filename: 'David Baldacci - Bullseye ( (EPUB).rar',
        downloaded_format: 'rar',
        size: '228.2KB',
        labels: [],
        country: nil
      },
      {
        line: '!MusicWench Tom Clancy [Op-Center 07] - Diviser pour regner.epub  ::INFO:: 378.1KB',
        source: 'MusicWench',
        author: 'Tom Clancy',
        title: 'Diviser pour regner',
        book_format: 'epub',
        series: 'Op-Center',
        series_number: '07',
        book_version: nil,
        filename: 'Tom Clancy [Op-Center 07] - Diviser pour regner.epub',
        downloaded_format: 'epub',
        size: '378.1KB',
        labels: [],
        country: nil
      },
      {
        line: '!Horla David Baldacci - La simple verite [FR].epub',
        source: 'Horla',
        author: 'David Baldacci',
        title: 'La simple verite',
        book_format: 'epub',
        series: nil,
        series_number: nil,
        book_version: nil,
        filename: 'David Baldacci - La simple verite [FR].epub',
        downloaded_format: 'epub',
        size: nil,
        labels: [],
        country: 'FR'
      },
      {
        line: "!Xon James Patterson - [Women's Murder Club 11] - 11th Hour - Maxine Paetro (epub).rar",
        source: 'Xon',
        author: 'James Patterson',
        title: '11th Hour',
        book_format: 'epub',
        series: "Women's Murder Club",
        series_number: '11',
        book_version: nil,
        filename: "James Patterson - [Women's Murder Club 11] - 11th Hour - Maxine Paetro (epub).rar",
        downloaded_format: 'rar',
        size: nil,
        labels: [],
        country: nil
      },
      {
        line: '!QuietSilence Clancy, Tom - Net Force Explorers 06 - Cyberspy.epub     --------------------- 152.78 KB',
        source: 'QuietSilence',
        author: 'Tom Clancy',
        title: 'Cyberspy',
        book_format: 'epub',
        series: 'Net Force Explorers',
        series_number: '06',
        book_version: nil,
        filename: 'Clancy, Tom - Net Force Explorers 06 - Cyberspy.epub',
        downloaded_format: 'epub',
        size: '152.78 KB',
        labels: [],
        country: nil
      },
      {
        line: '!QuietSilence Baldacci, David - One Good Deed.epub     ------------------------------------- 655.68 KB',
        source: 'QuietSilence',
        author: 'David Baldacci',
        title: 'One Good Deed',
        book_format: 'epub',
        series: nil,
        series_number: nil,
        book_version: nil,
        filename: 'Baldacci, David - One Good Deed.epub',
        downloaded_format: 'epub',
        size: '655.68 KB',
        labels: [],
        country: nil
      }

    ]

    @phrases_with_labels = [
      {
        original: 'foo (bar)',
        phrase: 'foo',
        labels: ['bar']

      }, {
        original: ' foo ( bar)',
        phrase: 'foo',
        labels: ['bar']
      }, {
        original: 'foo (bar,baz)',
        phrase: 'foo',
        labels: %w[bar baz]
      }, {
        original: 'foo (bar, baz)',
        phrase: 'foo',
        labels: %w[bar baz]
      }, {
        original: ' foo [ bar, baz]',
        phrase: 'foo',
        labels: %w[bar baz]
      }, {
        original: 'Split Second (v4.0) (epub, prc)',
        phrase: 'Split Second',
        labels: %w[v4.0 epub prc]
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

  def test_parse_labels_off_phrase
    @phrases_with_labels.each do |phrase_with_label|
      phrase, labels = Irc::Books::ResultsParser.parse_labels_off_phrase(phrase_with_label[:original])
      assert_equal phrase_with_label[:phrase], phrase, phrase_with_label[:original]
      assert_equal phrase_with_label[:labels].sort, labels.sort, phrase_with_label[:original]
    end
  end
end
