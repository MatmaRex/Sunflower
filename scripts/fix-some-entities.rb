require 'sunflower-commontasks.rb'
require 'sunflower-listmaker.rb'

# EDIT WIKI URL BELOW
s=Sunflower.new

print "Logging in to #{s.wikiURL}... "
# EDIT USERNAME AND PASSWORD BELOW
s.login
print "done!\n"

print "Reading articles list... "
# EDIT FILENAME BELOW
str=HTTP.get(URI.parse('http://toolserver.org/~sk/cgi-bin/checkwiki/checkwiki.cgi?project=plwiki&view=bots&id=11&offset=0&limit=2500'))
list=str[(str.index('<pre>')+5)...(str.index('</pre>'))].strip.split(/\r?\n/)
print "done!\n\n"

# EDIT SUMMARY BELOW
$summary='poprawa encji na znaki Unicode, [[WP:SK]]'

list.each do |title|
	print "Reading page #{title}... "
	page=Page.get(title)
	print "done.\n"
	print "Modifying... "

	to='− → ← ↓ ↑ ∞ · • å à ñ ä ö ü ß – — ⇒ £ À ¢ ↔ " æ Å … ’ ‘'.split ' '
	from='&minus; &rarr; &larr; &darr; &uarr; &infin; &middot; &bull; &aring; &agrave; &ntilde; &auml; &ouml; &uuml; &szlig; &ndash; &mdash; &rArr; &pound; &Agrave; &cent; &harr; &quot; &aelig; &Aring; &hellip; &rsquo; &lsquo;'.split ' '
	
	from.each_index do |i|
		page.replace(from[i], to[i])
	end
	
	page.codeCleanup unless page.origText==page.text
	
	print "done.\n"
	print "Saving... "
	page.save
	print "done!\n\n"
end

print 'Finished! Press any key to close.'
gets