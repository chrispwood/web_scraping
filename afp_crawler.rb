#!/usr/bin/env ruby

require 'rubygems'
require 'mechanize'
require 'digest/md5'

class AFPCrawler
  def initialize()
    @url = 'http://www.afp.com/afpcom/en'
    @mechagent = Mechanize.new
    @mechagent.open_timeout = 120
    @mechagent.read_timeout = 120
    @mechagent.keep_alive = false
    @mechagent.max_history=4
  end

  def start()
  end
end

if __FILE__ == $0
  puts "Agence France Presse (AFP) Crawler"
  crawler = AFPCrawler.new()
  crawler.start()
end
