# frozen_string_literal: true

require 'date'
require_relative 'model'

module Model::GeneralMeeting
  # 総会
  class GeneralMeeting
    attr_reader :date, :times

    # @param date [MeetingDate] 開催日
    # @param times [Integer] 第n回
    def initialize(date, times)
      @date = date
      @times = times
    end
  end

  # 和暦
  class JapaneseEra
    attr_reader :start_date, :end_date, :kanji

    def initialize(start_date: , end_date: , kanji: )
      @start_date = start_date
      @end_date = end_date
      @kanji = kanji
    end

    # 与えられた日付が、自身（元号）の範囲に含まれるかを判定する
    #
    # @param date [Date] 日付
    def include?(date)
      start_date  = self.start_date
      end_date    = self.end_date || Date.today

      (start_date .. end_date).include? date.to_date
    end

    # 与えられた日付の年を、自身の元号における和暦の文字列に変換する
    #
    # @param date [Date] 日付
    def format_year(date)
      year = self.era_year_of(date)
      year = if year.equal? 1
        then '元年'
        else "#{year}年"
        end

      "#{self.kanji}#{year}"
    end

    # 与えられた日付の年を、自身の元号における年に変換する
    #
    # @param date [Date] 日付
    def era_year_of(date)
      date = date.to_date
      raise ArgumentError, "与えられた日付が、元号の開始日より前です。"   if date < @start_date
      raise ArgumentError, "与えられた日付が、元号の終了日より後ろです。" if @end_date and date > @end_date

      date.to_date.year - self.start_date.year + 1
    end

    # 与えられた日付の年に対応する元号を返す
    #
    # @param date [Date] 日付
    def self.from(date)
      ERAS.find {|era| era.include?(date.to_date) }
    end

    # 与えられた日付の年を、和暦の文字列に変換する
    #
    # @param date [Date] 日付
    def self.format_year(date)
      era = self.from(date)

      raise ArgumentError, "日付に対応する元号はありません。コードの修正が必要かもしれません。" if era.nil?

      era.format_year(date)
    end

    def self.format_date(date)
      "#{self.format_year(date)}" + date.strftime("%m月%d日")
    end

    private_class_method :new

    SHOWA  = new start_date: Date.new(1926, 12, 25), end_date: Date.new(1989, 1,  7), kanji: '昭和'
    HEISEI = new start_date: Date.new(1989, 1, 8),   end_date: Date.new(2019, 4, 30), kanji: '平成'
    NEW    = new start_date: Date.new(2019, 5, 1),   end_date: nil                  , kanji: '新年号'

    ERAS = [ SHOWA, HEISEI, NEW ]
  end

  # 総会開催日
  class MeetingDate
    attr_reader :date
    protected :date

    # @param 
    def initialize(date)
      @date = date.to_date
    end

    def ==(other)
      self.date == other.date
    end

    def to_s
      @date.strftime("%Y-%m-%d %a")
    end

    def format_japanese_date
      JapaneseEra.format_date(@date)
    end

    def fiscal_year
      @date.year - (@date.month < 4 ? 1 : 0)
    end

    def fiscal_japanese_year
      JapaneseEra.format_year(@date)
    end

    # 前期
    def is_first_semester?
      (4..9).include? @date.month
    end

    # 後期
    def is_second_semester?
      not self.is_first_semester?
    end

    def semester
      %w{前期 後期}[semester_number - 1]
    end

    def semester_number
      case
      when is_first_semester?  then 1
      when is_second_semester? then 2
      else
        raise RuntimeError, "実装に問題があります: 学期の算出処理が正しくありません"
      end
    end
  end

  class Ordinal
    KANJI_DIGITS        = %w{零 一 二 三 四 五 六 七 八 九}.freeze
    KANJI_SUFFIXES      = %w{十 百 千}.freeze
    KANJI_META_SUFFIXES = %w{万 億 兆 京}.freeze

    RANGE = 1...(10000 ** KANJI_META_SUFFIXES.length)

    attr_reader :value
    protected :value

    def self.estimate(date)
      new(date.semester_number)
    end

    def initialize(value)
      raise ArgumentError, "範囲外の値です: #{value}" unless RANGE.include?(value&.to_i)

      @value = value.to_i
    end

    def to_i 
      @value
    end

    def ==(other)
      self.value == other.value
    end

    def kanji

      def digits
        @value.to_s(10).chars.map(&:to_i)
      end

      # 桁の配列を逆順で受け取り、漢字の配列を返す
      def four_digits_conv(digits)
        digits.each_with_index.flat_map {|digit_index, suffix_index|

          digit  = KANJI_DIGITS[digit_index]
          suffix = suffix_index.zero? ? "" : KANJI_SUFFIXES[suffix_index - 1]

          case
          when digit_index == 0                      then []
          when suffix_index >= 1 && digit_index == 1 then [suffix]
          else                                            [suffix, digit]
          end
        }.to_a
      end

      digits.reverse.each_slice(4).each_with_index.flat_map {|digits, meta_index|
        four_digits = four_digits_conv(digits)
        meta = meta_index.zero? ? "" : KANJI_META_SUFFIXES[meta_index - 1]

        four_digits.empty? ? "" : [ meta, four_digits ].join
      }.join.reverse
    end
  end
end
