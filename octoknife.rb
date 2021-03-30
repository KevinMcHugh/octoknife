require 'curses'
# TODO add sushi, love
class Board
  attr_reader :entities
  def initialize
    @entities = []
  end
  def add_entity(entity)
    @entities << entity
  end

  def render

  end
end

module DOneHundred
  def d100_beats(check)
    rand(100) > check
  end
end

class Octopus
  include DOneHundred

  def self.avatar; '🐙🔪'; end
  def self.inverse_avatar; "" * avatar.length; end

  # DIRECTIONS = ['UP', 'DOWN', 'LEFT', 'RIGHT']
  DIRECTIONS = ['DOWN']
  attr_reader :x, :y, :direction_change_propensity
  def initialize(x,y, win)
    @x,@y, @name = x,y, 'Beavis'
    @win = win
    @direction_change_propensity = (1..4).to_a.sample * 20
    change_direction
    update_position
  end

  def move
    clearable_y, clearable_x = @y, @x
    case @direction
    when 'UP'
      @y == 0 ? @y = @win.maxy : @y -=1
    when 'DOWN'
      @y == @win.maxy ? @y = 0 : @y += 1
    when 'LEFT'
      @x == 0 ? @x = @win.maxx : @x -=1
    when 'RIGHT'
      @x == @win.maxx ? @x = 0 : @x += 1
    end
    update_position(clearable_y, clearable_x)
    change_direction if d100_beats(direction_change_propensity)
  end

  private
  def update_position(clearable_y=nil, clearable_x=nil)
    # return if clearable_y == @y && clearable_x == @x
    old_x, old_y = @win.curx, @win.cury
    if clearable_y && clearable_x
      # @win.setpos(@y, @x + 30)
      # @win.addstr "clearing [#{clearable_x}, #{clearable_y}] to move to [#{@x}, #{@y}]"
      @win.setpos(clearable_y, clearable_x)
      @win.addstr(self.class.inverse_avatar)
    end
    @win.setpos(@y, @x)
    @win.addstr(self.class.avatar)
    @win.setpos(old_y, old_x)
  end

  def change_direction
    @direction = DIRECTIONS.sample
  end
end

def center_on_line(win, y, text)
  x = (win.maxx - text.length) / 2
  win.setpos(y, x)
  win.addstr(text)
end

def render_screen
  Curses.init_screen

  begin
    win = Curses.stdscr

    Curses.start_color
    Curses.noecho
    Curses.cbreak
    Curses.init_pair(1, Curses::COLOR_RED, Curses::COLOR_BLUE)

    x = win.maxx / 2
    y = win.maxy / 4
    win.setpos(y, x)
    center_on_line(win, y, "WELCOME TO OCTOPUS KNIFE")
    center_on_line(win, y+1, "press q to leave...if you dare")

    octos = 10.times.map { |i| Octopus.new(1, 1, win) }
    key_listener = Thread.new do
      loop {Thread.current[:key] = win.getch}
    end

    10.times do
      return if key_listener[:key] == 'q'
      octos.map(&:move)
      win.refresh
      sleep(1.0/20)
    end
    sleep 30
  ensure
    Curses.close_screen
  end
end

render_screen
