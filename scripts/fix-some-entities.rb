# coding: utf-8

require 'sunflower'
s = Sunflower.new.login

url = 'http://toolserver.org/~sk/cgi-bin/checkwiki/checkwiki.cgi?project=plwiki&view=bots&id=11&offset=0&limit=2500'

print "Reading articles list... "
# EDIT FILENAME BELOW
str=Net::HTTP.get(URI.parse(url))
list=str[(str.index('<pre>')+5)...(str.index('</pre>'))].strip.gsub('&#039;', "'").split(/\r?\n/).uniq
print "done (#{list.length} to do)!\n\n"

# EDIT SUMMARY BELOW
s.summary='poprawa encji na znaki Unicode, [[WP:SK]]'

list.each do |title|
	print "Reading page #{title}... "
	page=Page.new(title)
	print "done.\n"
	print "Modifying... "

	to='− → ← ↓ ↑ ∞ · • å à ñ ä ö ü ß – — ⇒ £ À ¢ ↔ " æ Å … ’ ‘'.split ' '
	from='&minus; &rarr; &larr; &darr; &uarr; &infin; &middot; &bull; &aring; &agrave; &ntilde; &auml; &ouml; &uuml; &szlig; &ndash; &mdash; &rArr; &pound; &Agrave; &cent; &harr; &quot; &aelig; &Aring; &hellip; &rsquo; &lsquo;'.split ' '
	
	from.each_index do |i|
		page.replace(from[i], to[i])
	end
	
	page.code_cleanup unless page.orig_text==page.text
	
	print "done.\n"
	print "Saving... "
	page.save
	print "done!\n\n"
end
