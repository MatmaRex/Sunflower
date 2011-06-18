# coding: utf-8

require 'sunflower'
s = Sunflower.new.login

url = 'http://toolserver.org/~sk/cgi-bin/checkwiki/checkwiki.cgi?project=plwiki&view=bots&id=16&offset=0&limit=2500'

print "Reading articles list... "
# EDIT FILENAME BELOW
str=Net::HTTP.get(URI.parse(url))
list=str[(str.index('<pre>')+5)...(str.index('</pre>'))].strip.split(/\r?\n/).uniq
print "done!\n\n"

# EDIT SUMMARY BELOW
s.summary='poprawa znaków kontrolnych Unicode, [[WP:SK]]'

list.each do |title|
	print "Reading page #{title}... "
	page=Page.new(title)
	print "done.\n"
	print "Modifying... "

	page.replace(/﻿|‎|​/, "")
	
	
	page.code_cleanup
	
	print "done.\n"
	print "Saving... "
	page.save
	print "done!\n\n"
end
