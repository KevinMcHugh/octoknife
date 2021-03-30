require 'curses'
require 'pry'
# TODO add sushi, love
module Chance
  def d100_beats?(check)
    rand(100) > check
  end
end

class UnmovingEntity
  attr_reader :avatar, :x, :y
  def initialize(x, y, avatar, board)
    @x, @y, @avatar, @board = x, y, avatar, board
    @present = true
  end

  def inverse_avatar; " " * 2 * avatar.length; end
  def update; end

  # TODO: update this when there's non-food items
  def food?; true; end
  def consume
    raise "inedible!" unless food?
    @board.remove_entity(self)
  end
end

class Board
  include Chance

  attr_reader :entities, :locations

  def initialize(win)
    @win = win
    @entities = []
    @locations = Array.new(@win.maxx, [])
  end

  def add_entity(entity)
    @entities << entity
    borrow_cursor do |win|
      win.setpos(entity.y, entity.x)
      win.addstr(entity.avatar)
      locations[entity.x][entity.y] ||= []
      locations[entity.x][entity.y] << entity
    end
  end

  def remove_entity(entity)
    @entities.delete(entity)
    locations[entity.x][entity.y].delete(entity)
  end

  def render_step
    add_food
    entities.each do |entity|
      update(entity)
    end
    @win.refresh
  end

  # delegates...
  def maxx; @win.maxx; end
  def maxy; @win.maxy; end
  def near(x,y)
    (locations[x-1..x+1][y-1..y+1]&.flatten || []).compact
  end

  private
  def update(entity)
    borrow_cursor do |win|
      # handle clearing old position
      win.setpos(entity.y,entity.x)
      win.addstr(entity.inverse_avatar)

      entity.update

      win.setpos(entity.y, entity.x)
      win.addstr(entity.avatar)
      locations[entity.x][entity.y] ||= []
      locations[entity.x][entity.y] << entity
    end
  end

  def borrow_cursor
    old_x, old_y = @win.curx, @win.cury
    yield @win
    @win.setpos(old_y, old_x)
  end

  def add_food
    if d100_beats?(75)
      add_entity(UnmovingEntity.new(rand(maxx - 5), rand(maxy - 2), ?🍣, self))
    end
  end
end

class Octopus
  include Chance

  def avatar; '🐙🔪'; end
  # TODO - I want not length but like, utf8 length or something - hence the doubling here
  def inverse_avatar; " " * 2 * avatar.length; end

  DIRECTIONS = ['UP', 'DOWN', 'LEFT', 'RIGHT']
  attr_reader :x, :y, :direction_change_propensity
  def initialize(x,y, board)
    @x,@y, @name = x,y, 'Beavis'
    @y += 1 if @y.zero?
    # TODO: factor out board from octopus
    @board = board
    @direction_change_propensity = (1..4).to_a.sample * 20
    change_direction
  end

  def update
    change_direction if d100_beats?(direction_change_propensity)
    nearby = @board.near(x,y)
    if food = nearby&.find(&:food?)
      @x, @y = food.x, food.y
      consume(food)
    else
      case @direction
      when 'UP'
        @y == 1 ? @direction ='DOWN' : @y -=1
      when 'DOWN'
        @y == @board.maxy - 2 ? @direction = 'UP' : @y += 1
      when 'LEFT'
        @x == 1 ? @direction = 'RIGHT' : @x -=1
      when 'RIGHT'
        # The five here is again because the knife takes an additional character
        @x >= @board.maxx - 5 ? @direction = 'LEFT' : @x += 1
      end
    end
  end

  def to_s
    "<Octopus @x=#{@x} @y=#{@y}>"
  end

  def food?; false; end

  private
  def change_direction
    @direction = DIRECTIONS.sample
  end

  def consume(food)
    # TODO give a boon for well-fedness
    food.consume
  end
end

def center_on_line(win, y, text)
  x = (win.maxx - text.length) / 2
  win.setpos(y, x)
  win.addstr(text)
end

def render_screen
  Curses.init_screen
  win = Curses.stdscr
  board = Board.new(win)
  octos = 10.times.map { |i| board.add_entity(Octopus.new(rand(win.maxx - 4), rand(win.maxy - 1), board)) }

  begin
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

    key_listener = Thread.new do
      loop {Thread.current[:key] = win.getch}
    end

    loop do
      return if key_listener[:key] == 'q'
      board.render_step
      sleep(1.0/10)
    end
  ensure
    maxx = win.maxx
    Curses.close_screen
    Curses.curs_set(1)
    puts maxx
    puts octos.map(&:to_s)
  end
end

render_screen
