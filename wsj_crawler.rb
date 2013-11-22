#!/usr/bin/env ruby

require 'rubygems'
require 'mechanize'
require 'digest/md5'

class WSJCrawler
  def initialize()
    @url = 'http://online.wsj.com/search/term.html?KEYWORDS=ENTER SEARCH TERMS HERE'
    @mechagent = Mechanize.new
    @mechagent.open_timeout = 120
    @mechagent.read_timeout = 120
    @mechagent.keep_alive = false
    @mechagent.max_history=4
  end

  def start()
    puts "starting..."

    curPage = 1
    curDate = Date.today.strftime('%m/%d/%y')
    oldDate = (Date.today - 365*2).strftime('%m/%d/%y')

    # login
    loginpage = @mechagent.get('http://wsj.com')
    loginForm = loginpage.form('login_form')
    loginForm.field_with(:name=>'user').value = 'chris.p.wood@me.com'
    loginForm.field_with(:name=>'password').value = 'wallStreetWood'
    newspage = loginForm.submit()

    # search
    newspage = @mechagent.get(@url)
    newspage = newspage.link_with(:text=>/Advanced Search/).click
    advSearchForm = newspage.form('search_form')
    advSearchForm.field_with(:name=>'page_no').value = curPage.to_s
    advSearchForm.field_with(:name=>'KEYWORDS').value = 'ENTER SEARCH TERMS HERE'
    advSearchForm.field_with(:name=>'date_range').value = '2 years'
    advSearchForm.field_with(:name=>'sort_by').value = 'date'
    advSearchForm.field_with(:name=>'fromDate').value = oldDate
    advSearchForm.field_with(:name=>'toDate').value = curDate

    newspage = advSearchForm.submit()
    newspage.content=~/<li class="listFirst">\s\d+-\d+ of ([\d,]+)<\/li>/
    results = $1
    puts "retrieving #{results} results"

    while(true)
      puts "crawling page #{curPage}"

      newspage.content=~/<li class="listFirst">(\s\d+-\d+ of ([\d,]+))<\/li>/
      results = $1
      puts "results: #{results}"
      
      # get all the articles on the page
      newspage.links.each do |articleLink|
        if not articleLink.attributes['class']=~/^mjLinkItem/
          next
        end

        author = ''
        allText = ''
        text = ''
        title = ''
        articleDate = ''
        articleLink.uri.to_s=~/^(.*?)\?KEYWORDS.*$/
        coreLink = $1
        if(coreLink=~/^\/(?:article|video)/)
          coreLink = 'http://online.wsj.com'+coreLink
        end

        # get article
        puts "  retrieving article: #{articleLink.text} ::: #{coreLink}"
        articlePage = ''
        attempts = 0
        while(true)
          if(attempts>=5)
            puts "    unable to retrieve article.  skipping..."
            break
          end
          begin
            articlePage = @mechagent.get(coreLink)
            break
          rescue Mechanize::ResponseCodeError => error
            # try again
            puts "    error retrieving (#{coreLink}).  Trying again..."
          end
          attempts = attempts + 1
        end
        if(attempts>=5)
          next
        end
        articlePage.search("li[@class='dateStamp first']").each do |dateItem|
          articleDate = dateItem.text
        end
        articlePage.search("div[@class^='articleHeadlineBox headlineType-newswire']").search("h1").each do |titleItem|
          title = titleItem.text
        end
        articlePage.search("div[@class='articlePage']").each do |articleText|
          seenAuthor = false
          allText = articleText.text
          articleText.children.each do |child|
            if(seenAuthor)
              text<<child.text
            elsif(child.text=~/By (.*)$/)
              seenAuthor = true
              author = $1
            end
          end
        end

        # unusable article - skip
        if(text=='')
          if(allText=='')
            puts "    WARNING!  No text for article link #{coreLink}; title: #{title}"
            next
          else
            text = allText
          end
        end

        # print the article content
        digest = Digest::MD5.hexdigest(coreLink)
        filename = 'WSJ.'+digest+'.xml'
        File.open(filename,'w') {|f|
          f.write("<article>\n")
          f.write("  <report-date>#{articleDate}</report-date>\n")
          f.write("  <crawl-date>#{Date.today.to_s}</crawl-date>\n")
          f.write("  <news-source>WSJ</news-source>\n")
          f.write("  <url>#{coreLink}</url>\n")
          f.write("  <title>#{title}</title>\n")
          f.write("  <author>#{author}</author>\n")
          f.write("  <text>#{text}</text>\n")
          f.write("</article>")
        }
      end

      # go to next page
      curPage = curPage + 1
      nextPageLink = newspage.link_with(:text=>curPage.to_s)
      if nextPageLink == nil
        break
      else
        advSearchForm = newspage.form('search_form')
        advSearchForm.field_with(:name=>'page_no').value = curPage.to_s
        newspage = advSearchForm.submit()
        @mechagent.history.clear()
      end
    end

    puts "completed crawling"

  end
end

if __FILE__ == $0
  puts "WSJ Crawler"
  crawler = WSJCrawler.new()
  crawler.start()
end
