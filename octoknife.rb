require 'curses'
# TODO add sushi, love
# class Board
#   attr_reader :entities
#   def initialize
#     @entities = []
#   end
#   def add_entity(entity)
#     @entities << entity
#   end

#   def render

#   end
# end

module DOneHundred
  def d100_beats?(check)
    rand(100) > check
  end
end

class Octopus
  include DOneHundred

  def self.avatar; '🐙🔪'; end
  # TODO - I want not length but like, utf8 length or something - hence the doubling here
  def self.inverse_avatar; " " * 2 * avatar.length; end

  DIRECTIONS = ['UP', 'DOWN', 'LEFT', 'RIGHT']
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
    change_direction if d100_beats?(direction_change_propensity)
    case @direction
    when 'UP'
      @y == 1 ? @direction ='DOWN' : @y -=1
    when 'DOWN'
      @y == @win.maxy - 2 ? @direction = 'UP' : @y += 1
    when 'LEFT'
      @x == 1 ? @direction = 'RIGHT' : @x -=1
    when 'RIGHT'
      # The four here is again because the knife takes an additional character
      @x == @win.maxx - 4 ? @direction = 'LEFT' : @x += 1
    end
    update_position(clearable_y, clearable_x)
  end

  private
  def update_position(clearable_y=nil, clearable_x=nil)
    return if clearable_y == @y && clearable_x == @x
    old_x, old_y = @win.curx, @win.cury
    if clearable_y && clearable_x
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
    Curses.curs_set(0)
    Curses.start_color
    Curses.noecho
    Curses.cbreak
    Curses.init_pair(1, Curses::COLOR_RED, Curses::COLOR_BLUE)
    win.box('|', '-')

    x = win.maxx / 2
    y = win.maxy / 4
    win.setpos(y, x)
    center_on_line(win, y, "WELCOME TO OCTOPUS KNIFE")
    center_on_line(win, y+1, "press q to leave...if you dare")

    octos = 10.times.map { |i| Octopus.new(rand(win.maxx), rand(win.maxy), win) }
    key_listener = Thread.new do
      loop {Thread.current[:key] = win.getch}
    end

    (win.maxy * 2).times do
      return if key_listener[:key] == 'q'
      octos.map(&:move)
      win.refresh
      sleep(1.0/10)
    end
    sleep 10
  ensure
    Curses.close_screen
    Curses.curs_set(1)
  end
end

render_screen
