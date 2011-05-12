require 'hpricot'
require 'net/http'
include Net

def get(url)
	return HTTP.get(URI.parse(url))
end

f=File.open('id2team.txt','w')
f.sync=true

((1..4).to_a + (12..15).to_a).each do |i|
	page=get("http://www.soccerbase.com/teams.sd?competitionid=#{i}")
	h=Hpricot.parse page
	
	h2=Hpricot.parse h.search('table table table')[2].inner_html
	
	h2.search('tr').each do |tr|
		begin
			if tr.at('b').inner_html.strip=='Team'||tr.inner_html.index('<script')||tr.inner_html.index('<img')
				next 
			end
		rescue Exception
		end
		id=tr.at('a')['href'].sub(/\A.+?(\d+)\Z/, '\1')
		team=tr.at('a').inner_html.strip
		
		f.puts "#{id}\t#{team}"
	end
	
	
end