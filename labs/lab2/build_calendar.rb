require 'date'

TIMES = ["12:00", "15:00", "18:00"].freeze
PARALLEL_GAMES_PER_TIME = 2
ALLOWED_WDAYS = [5, 6, 0].freeze 

def die(msg)
  warn msg
  exit 1
end

def validate_args!
  if ARGV.length != 4
    die "Usage: ruby build_calendar.rb teams.txt 01.08.2026 01.06.2027 calendar.txt"
  end
end

def parse_date!(str)
  Date.strptime(str, "%d.%m.%Y")
rescue ArgumentError
  die "Invalid date format: #{str}. Use DD.MM.YYYY"
end

def read_teams!(file)
  die "File not found: #{file}" unless File.exist?(file)

  teams = []
  seen = {}

  File.readlines(file, chomp: true, encoding: "UTF-8").each_with_index do |raw, idx|
    line = raw.strip
    next if line.empty?

    line = line.sub(/^\d+\.\s*/, "")

    parts = line.split(/\s+[—-]\s+/)
    if parts.size != 2
      die "Invalid team line at #{idx + 1}: #{raw}\nExpected format: 'N. Team — City'"
    end

    name = parts[0].strip
    city = parts[1].strip
    die "Empty team or city at line #{idx + 1}: #{raw}" if name.empty? || city.empty?

    key = "#{name}||#{city}"
    die "Duplicate team at line #{idx + 1}: #{raw}" if seen[key]

    seen[key] = true
    teams << { name: name, city: city }
  end

  die "Need at least 2 teams" if teams.size < 2
  teams
end

def generate_matches(teams)
  matches = []
  teams.combination(2) { |a, b| matches << [a, b] }
  matches
end

def allowed_day?(date)
  ALLOWED_WDAYS.include?(date.wday)
end

def generate_slots(start_date, end_date)
  slots = []
  current = start_date

  while current <= end_date
    if allowed_day?(current)
      TIMES.each do |time|
        PARALLEL_GAMES_PER_TIME.times do
          slots << { date: current, time: time }
        end
      end
    end
    current += 1
  end

  slots
end

def distribute_matches_evenly!(matches, slots)
  die "Not enough available slots for all matches" if matches.size > slots.size

  schedule = []

  if matches.size == 1
    i = slots.size / 2
    slot = slots[i]
    schedule << {
      date: slot[:date],
      time: slot[:time],
      home: matches[0][0],
      away: matches[0][1]
    }
    return schedule
  end

  used = {}
  max_index = slots.size - 1
  denom = matches.size - 1

  matches.each_with_index do |match, i|
    idx = (i * max_index.to_f / denom).round

    j = idx
    while used[j] && j < slots.size
      j += 1
    end
    if j >= slots.size
      j = idx
      while used[j] && j >= 0
        j -= 1
      end
    end
    die "Internal error: cannot find free slot (slots too small?)" if j < 0 || j >= slots.size

    used[j] = true
    slot = slots[j]

    schedule << {
      date: slot[:date],
      time: slot[:time],
      home: match[0],
      away: match[1]
    }
  end

  schedule.sort_by { |g| [g[:date], g[:time]] }
end

def format_calendar(schedule)
  lines = []
  lines << "SPORTS CALENDAR"
  lines << "Generated at: #{Time.now}"
  lines << ""

  grouped = schedule.group_by { |g| g[:date] }.sort_by { |date, _| date }

  grouped.each do |date, games|
    lines << date.strftime("%A, %d.%m.%Y")
    lines << "-" * 60

    games.sort_by { |g| g[:time] }.each do |g|
      home = "#{g[:home][:name]} (#{g[:home][:city]})"
      away = "#{g[:away][:name]} (#{g[:away][:city]})"
      lines << "#{g[:time]}  #{home}  vs  #{away}"
    end

    lines << ""
  end

  lines.join("\n")
end

def write_file!(path, content)
  begin
    File.write(path, content)
  rescue => e
    die "Cannot write to file #{path}: #{e.message}"
  end
end

# ---- main ----
validate_args!

teams_file, start_str, end_str, out_file = ARGV

start_date = parse_date!(start_str)
end_date = parse_date!(end_str)
die "Start date must be <= end date" if start_date > end_date

teams = read_teams!(teams_file)
matches = generate_matches(teams)
slots = generate_slots(start_date, end_date)
die "No available slots in given range (only Fri/Sat/Sun are allowed)" if slots.empty?

schedule = distribute_matches_evenly!(matches, slots)
calendar_text = format_calendar(schedule)
write_file!(out_file, calendar_text)

puts "OK: #{schedule.size} matches scheduled into #{out_file}"