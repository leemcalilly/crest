require "csv"

namespace :crest do
  desc "Import the United States record from db/source (CC0 open data)"
  task import: :environment do
    source = Rails.root.join("db/source")
    US = "United States"

    ActiveRecord::Base.transaction do
      Goal.delete_all
      Match.delete_all
      Player.delete_all
      Cycle.delete_all

      # --- Cycles -------------------------------------------------------
      rows = CSV.read(source.join("results.csv"), headers: true)
      us_rows = rows.select { |r| [ r["home_team"], r["away_team"] ].include?(US) }
      first_year = us_rows.first["date"][0, 4].to_i

      cycles = []
      cycles << Cycle.create!(slug: "pre-#{Cycle::WORLD_CUP_YEARS.first}",
                              name: "Before the World Cup",
                              starts_on: Date.new(first_year, 1, 1),
                              ends_on: Date.new(Cycle::WORLD_CUP_YEARS.first - 1, 12, 31))
      previous = Cycle::WORLD_CUP_YEARS.first - 1
      Cycle::WORLD_CUP_YEARS.each do |year|
        cycles << Cycle.create!(slug: year.to_s, name: "The #{year} cycle", world_cup_year: year,
                                starts_on: Date.new(previous + 1, 1, 1),
                                ends_on: Date.new(year, 12, 31))
        previous = year
      end
      puts "cycles: #{Cycle.count}"

      # --- Matches ------------------------------------------------------
      by_key = {}
      us_rows.each do |r|
        played_on = Date.parse(r["date"])
        cycle = cycles.find { |c| c.starts_on <= played_on && c.ends_on >= played_on }
        next unless cycle

        home = r["home_team"] == US
        match = Match.create!(
          cycle: cycle, played_on: played_on,
          opponent: home ? r["away_team"] : r["home_team"],
          us_score: (home ? r["home_score"] : r["away_score"]).to_i,
          opponent_score: (home ? r["away_score"] : r["home_score"]).to_i,
          tournament: r["tournament"], city: r["city"], country: r["country"],
          neutral: r["neutral"] == "TRUE", home: home)
        by_key[[ r["date"], r["home_team"], r["away_team"] ]] = match
      end
      puts "matches: #{Match.count}"

      # --- Goals and players -------------------------------------------
      players = {}
      CSV.foreach(source.join("goalscorers.csv"), headers: true) do |r|
        match = by_key[[ r["date"], r["home_team"], r["away_team"] ]]
        next unless match

        for_us = r["team"] == US
        player = nil
        if for_us
          player = players[r["scorer"]] ||=
            Player.create!(name: r["scorer"], slug: Player.slug_for(r["scorer"]))
        end

        Goal.create!(match: match, player: player, scorer_name: r["scorer"], for_us: for_us,
                     minute: r["minute"].presence&.to_i,
                     penalty: r["penalty"] == "TRUE", own_goal: r["own_goal"] == "TRUE")
      end
      puts "players: #{Player.count}  goals: #{Goal.count}"
    end
  end
end
