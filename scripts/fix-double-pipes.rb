# coding: utf-8

require 'sunflower'
s = Sunflower.new.login

url = 'http://toolserver.org/~sk/cgi-bin/checkwiki/checkwiki.cgi?project=plwiki&view=bots&id=32&offset=0&limit=2500'

print "Reading articles list... "
# EDIT FILENAME BELOW
str=Net::HTTP.get(URI.parse(url))
list=str[(str.index('<pre>')+5)...(str.index('</pre>'))].strip.split(/\r?\n/).uniq
print "done!\n\n"

# EDIT SUMMARY BELOW
s.summary='poprawa podwójnych znaków pipe w linkach, [[WP:SK]]'

list.each do |title|
	print "Reading page #{title}... "
	page=Page.new(title)
	print "done.\n"
	print "Modifying... "

	page.replace(/\[\[([^\|\]]+)\|\|([^\]]+)\]\]/, '[[\1|\2]]')
	page.code_cleanup unless page.orig_text==page.text
	
	print "done.\n"
	print "Saving... "
	page.save
	print "done!\n\n"
end
