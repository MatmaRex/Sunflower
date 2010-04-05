#!/usr/bin/ruby
print "Content-type: text/html; charset=utf8\n\r\n"
$stderr=$stdout

require 'sunflower-core.rb'

s=Sunflower.new('pl.wikipedia.org')
s.log=false
s.login
cgi=CGI.new


puts ''
puts '<p>Get list for: <form action="author-list.rb" method="GET"><input name="title"> <input type="submit" value="Go!"></form></p>'

if cgi['title'] && cgi['title']!=''
	puts '<p>List of authors of '+cgi['title']+':</p>'

	users=[]
	hash=s.API("action=query&prop=revisions&titles=#{CGI.escape(cgi['title'])}&rvprop=user&rvlimit=5000")
	hash['query']['pages'].values[0]['revisions'].each do |r|
		users<<r['user']
	end
	while hash['query-continue']
		hash=s.API("action=query&prop=revisions&titles=#{CGI.escape(cgi['title'])}&rvprop=user&rvlimit=5000&rvstartid=#{hash['query-continue']['revisions']['rvstartid']}")
		hash['query']['pages'].values[0]['revisions'].each do |r|
			users<<r['user']
	end
	end

	users.uniq!


	puts '<ul><li>'+users.join('</li><li>')+'</li></ul>'
end

