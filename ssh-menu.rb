#!/usr/bin/env ruby

require 'curses'
include Curses

def config_app
  @index = 0 
  ssh_file = '~/.ssh/config'
  hosts = read_ssh(ssh_file)
  { ssh_file: ssh_file,
    hosts:  hosts,
    max_index: hosts.size - 1,
    min_index: 0 } 
end

def read_ssh(path_to_file)
  ssh_path = File.expand_path(path_to_file)
  config_file = File.read(ssh_path).lines.grep(/^Host/)
  config_file.map { |line| line.sub(/^Host/, '').strip }.sort
end

def init_curses
  init_screen
  start_color
  curs_set(0)
  noecho
  init_pair(1, 1, 0)
end

def clear_screen_and_refresh(window)
  (window.maxy - window.cury).times {window.deleteln()}
  window.refresh
end

def draw_screen(window, settings)
  hosts = settings[:hosts]
  window.setpos(0,0)
  hosts.each.with_index(0) do |str, index|
    if index == @index
      window.attron(color_pair(1)) { window << str }
    else
      window << str 
    end 
    clrtoeol
    window << "\n"
  end 
  clear_screen_and_refresh(window)
end

def handle_input(window, settings)
  hosts = settings[:hosts]
  max_index = settings[:max_index]
  min_index = settings[:min_index]
  str =  window.getch.to_s
  case str
  when 'j'
    @index = @index >= max_index ? max_index : @index + 1
  when 'k'
    @index = @index <= min_index ? min_index : @index - 1
  when '10' # ENTER key
    @selected = hosts[@index]
    exit 0
  when 'q' then exit 0
  end
end

def main(s)
  win = Curses::Window.new(0, 0, 1, 2)
  loop do
    draw_screen(win, s)
    handle_input(win, s)
  end
end

def run_app
  settings = config_app
  begin
    init_curses
    main(settings)
  ensure
    close_screen
    exec "ssh #{@selected} if @selected"
  end
end

run_app
