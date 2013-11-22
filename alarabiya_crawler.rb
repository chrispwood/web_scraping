#!/usr/bin/env ruby

require 'rubygems'
require 'mechanize'
require 'digest/md5'

class AlArabiyaCrawler
  def initialize()
    @url = 'http://english.alarabiya.net/index/searchengine/search_en?q=ENTER SEARCH TERM'
    @mechagent = Mechanize.new
    @mechagent.open_timeout = 120
    @mechagent.read_timeout = 120
    @mechagent.keep_alive = false
    @mechagent.max_history=4
  end

  def start()
    puts "starting..."
    curPage = 1
    tmpUrl = @url+"&s=#{((curPage-1)*10).to_s}"
    newspage = @mechagent.get(tmpUrl)
    newspage.content=~/\(About\s+(\d+)\s+results\)/
    totalResults = Integer($1)
    totalPages = (totalResults.to_f/10.to_f).ceil
    puts "retrieving #{totalResults} results on #{totalPages} pages"

    curPage = 85 
    tmpUrl = @url+"&s=#{((curPage-1)*10).to_s}"
    newspage = @mechagent.get(tmpUrl)

    # search
    while(curPage<=totalPages)
      puts "crawling page #{curPage}"

      newspage.search("div[@class='search-box']").each do |searchBox|
        searchBox.search("a").each do |link|
          puts "  retrieving article: #{link.text} ::: #{link['href']}"
          articlepage = ''
          attempts = 0
          while(true)
            if(attempts>=5)
              puts "    unable to retrieve article.  skipping..."
              break
            end
            begin
              articlepage = @mechagent.get(link['href'])
              break
            rescue Mechanize::ResponseCodeError => error
              # try again
              puts "    error retrieving (#{link['href']}).  Trying again..."
            end
            attempts = attempts + 1
          end
          if(attempts>=5)
            next
          end

          author = ''
          text = ''
          date = ''
          title = ''

          begin
            articlepage.search("span[class='reporter-names']").each do |authorItem|
              author << authorItem.text + ' '
            end

            articlepage.search("div[class='main_body']").each do |textItem|
              text << textItem.text + "\n"
            end
            text.delete!("\C-M")
            text.strip!()

            articlepage.search("p[class='article-date']").each do |dateItem|
              date = dateItem.text
              # format: Thursday, 13 October 2011
              date=~/,\s*(\d+\s+\w+\s+\d+)\s*$/
              tmpDate = Date.strptime($1, "%d %b %Y")
              date = tmpDate
            end

            articlepage.search("h1").each do |titleItem|
              title = titleItem.text
              break
            end
            title.delete!("\C-M")
            title.strip!()

            # print the article content
            digest = Digest::MD5.hexdigest(link['href'])
            filename = 'AlArabiya.'+digest+'.xml'
            File.open(filename,'w') {|f|
              f.write("<article>\n")
              f.write("  <report-date>#{date}</report-date>\n")
              f.write("  <crawl-date>#{Date.today.to_s}</crawl-date>\n")
              f.write("  <news-source>Al-Arabiya</news-source>\n")
              f.write("  <url>#{link['href']}</url>\n")
              f.write("  <title>#{title}</title>\n")
              f.write("  <author>#{author}</author>\n")
              f.write("  <text>#{text}</text>\n")
              f.write("</article>")
            }
          rescue
            puts "    error parsing (#{link['href']}). Skipping..."
          end
          break
        end
      end

      @mechagent.history.clear()
      curPage = curPage + 1
      tmpUrl = @url+"&s=#{((curPage-1)*10).to_s}"
      newspage = @mechagent.get(tmpUrl)
    end
  end
end

if __FILE__ == $0
  puts "Al-Arabiya Crawler"
  crawler = AlArabiyaCrawler.new()
  crawler.start()
end
