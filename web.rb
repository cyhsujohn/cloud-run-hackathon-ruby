require 'sinatra'

$stdout.sync = true

configure do
  set :port, 8080
  set :bind, '0.0.0.0'
end

get '/' do
  'Let the battle begin!'
end

$running_count = 0
$mode = "attacking"
$hit_count = 0

post '/' do
  status 200
  @data = JSON.parse(request.body.read)
  hit_analysis

  case $mode
  when "running"
    case $running_count
    when 0
      $running_count = 3
      body ["L", "R"].sample
    when 1
      $running_count = 0
      $mode = "attacking"
      body "F"
    when 2
      $running_count -= 1
      body ["L", "R"].sample
    when 3
      $running_count -= 1
      body "F"
    end
  when "attacking"
    if !target.empty?
      body "T"
    elsif facing_wall
      body ["L", "R"].sample
    else
      body ["L", "R", "F"].sample
    end
  end
end

def arena_info(direction = "x", full_info = false)
  return @data["arena"]["dims"] if full_info
  if direction == "x"
    @data["arena"]["dims"][0]
  else
    @data["arena"]["dims"][1]
  end
end

def state
  @_state ||= @data["arena"]["state"]
end

def self_info
  @_self_info ||= state["https://cloud-run-hackathon-ruby-22mk7ghtqq-uc.a.run.app"] || state["https://YOUR_SERVICE_URL"]
end

def current_x
  @_current_x ||= self_info["x"]
end

def current_y
  @_current_y || self_info["y"]
end

def hit_analysis
  if self_info["wasHit"]
    $hit_count += 1
  else
    $hit_count = 0
  end

  $mode = "running" if $hit_count >= 3
end

def facing
  @_facing ||= self_info["direction"]
end

def search_x(facing)
  @_search_x ||= case facing
  when "W" then [current_x - 3, current_x - 2, current_x - 1]
  when "E" then [current_x + 1, current_x + 2, current_x + 3]
  end
end

def search_y(facing)
  @_search_y ||= case facing
  when "N" then [current_y - 3, current_y - 2, current_y - 1]
  when "S" then [current_y + 1, current_y + 2, current_y + 3]
  end
end

def target
  state.select do |k, v|
    case facing
    when "N", "S"
     v["x"] == current_x && search_y(facing).include?(v["y"])
    when "W", "E"
     v["y"] == current_y && search_x(facing).include?(v["x"])
    end
  end
end

def facing_wall
  case facing
  when "N"
    current_y == 0
  when "S"
    current_y == arena_info("y")
  when "W"
    current_x == 0
  when "E"
    current_x == arena_info("x")
  end
end