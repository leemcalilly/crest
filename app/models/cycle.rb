# A World Cup cycle: the years leading to and including a World Cup.
# This is crest's unit of time. Every date range on the site is a cycle.
class Cycle < ApplicationRecord
  WORLD_CUP_YEARS = [ 1930, 1934, 1938, 1950, 1954, 1958, 1962, 1966, 1970, 1974,
                      1978, 1982, 1986, 1990, 1994, 1998, 2002, 2006, 2010, 2014,
                      2018, 2022, 2026 ].freeze

  has_many :matches, dependent: :destroy

  scope :chronological, -> { order(:starts_on) }

  def self.for(date)
    find_by("starts_on <= ? AND ends_on >= ?", date, date)
  end

  def to_param = slug

  def previous = Cycle.where(ends_on: ...starts_on).order(:ends_on).last
  def next     = Cycle.where("starts_on > ?", starts_on).chronological.first

  def position = Cycle.chronological.pluck(:id).index(id) + 1
  def length_in_years = ends_on.year - starts_on.year + 1

  # 1939-1950 is one cycle of twelve years: no tournament was played.
  # The pre-1930 bucket is long by nature, so it is not interrupted.
  def interrupted? = world_cup_year.present? && length_in_years > 4

  def record = Match::Record.new(matches)
end
