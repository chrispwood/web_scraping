#!/usr/bin/env ruby

require 'rubygems'
require 'mechanize'

class XinhuaCrawler
  def initialize()
    @url = 'ENTER SEARCH URL HERE'
    @mechagent = Mechanize.new
    @mechagent.open_timeout = 120
    @mechagent.read_timeout = 120
    @mechagent.keep_alive = false
    @mechagent.max_history=4
  end

  def start()
    puts "starting..."

    pageNum = 257
    tmpUrl = @url + pageNum.to_s
    puts "retrieving: " + tmpUrl
    newspage = @mechagent.get(tmpUrl)
    links = newspage.links

    newspage.content=~/([\d,]+)&nbsp;results found/i
    totalResults = $1
    totalResults.delete!(",")
    totalResults = Integer(totalResults)
    resultsPerPage = 20
    totalPages = (totalResults.to_f/resultsPerPage.to_f).ceil

    puts "total results = #{totalResults}; resultsPerPage = 20; totalPages = #{totalPages}"

    while(pageNum<=totalPages)
      links.each {|link|
        if /^http:\/\/news\.xinhuanet\.com\/english/.match(link.uri.to_s)
          puts "  saving file: " + link.uri.to_s
          # need to open the link
          begin
            articlepage = @mechagent.get(link.uri)
          rescue Mechanize::ResponseCodeError => error
            puts "    skipping (error retrieving): #{error}"
            next
          end

          # find the article date - time
          articlepage.content=~/(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})/
          dateTime = $1
          if(dateTime==nil)
            puts "    skipping (non-standard format)"
            next
          end

          # get the title
          title = ''
          articlepage.search("div[@id='Title']").each do |item|
            title = item.text
            title.delete!("\C-M")
            title.strip!()
          end

          # get the article
          article = ''
          articlepage.search("div[@id='Content']").each do |item|
            article += item.text
          end
          article.delete!("\C-M")
          article.strip!()

          # print the article content
          link.uri.to_s=~/([^\/]+)\.html?$/i
          filename = dateTime[0..9] + '.' + $1 + '.xml'
          File.open(filename, 'w') {|f| 
            f.write("<article>\n")
            f.write("  <report-date>#{dateTime}</report-date>\n")
            f.write("  <crawl-date>#{Date.today.to_s}</crawl-date>\n")
            f.write("  <news-source>Xinhua</news-source>\n")
            f.write("  <url>#{link.uri}</url>\n")
            f.write("  <title>#{title}</title>\n")
            f.write("  <text>#{article}</text>\n")
            f.write("</article>")
          }

          #puts articlepage.content
        end
      }

      pageNum += 1
      tmpUrl = @url + pageNum.to_s
      puts "retrieving: " + tmpUrl
      while(true)
        begin
          newspage = @mechagent.get(tmpUrl)
          break
        rescue Mechanize::ResponseCodeError => error
          # do nothing
          puts "  error retrieving (#{error}).  Trying again..."
        end
      end
      links = newspage.links
    end
  end
end

if __FILE__ == $0
  puts "Xinhua Crawler"
  crawler = XinhuaCrawler.new()
  crawler.start()
end
