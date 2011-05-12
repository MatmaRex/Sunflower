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
str=HTTP.get(URI.parse('http://toolserver.org/~sk/cgi-bin/checkwiki/checkwiki.cgi?project=plwiki&view=bots&id=32&offset=0&limit=2500'))
list=str[(str.index('<pre>')+5)...(str.index('</pre>'))].strip.split(/\r?\n/)
print "done!\n\n"

# EDIT SUMMARY BELOW
$summary='poprawa podwójnych znaków pipe w linkach, [[WP:SK]]'

failcounter=0
list.each do |title|
	begin
		print "Reading page #{title}... "
		page=Page.get(title)
		print "done.\n"
		print "Modifying... "

		page.replace(/\[\[([^\|\]]+)\|\|([^\]]+)\]\]/, '[[\1|\2]]')
		page.codeCleanup unless page.origText==page.text
		
		print "done.\n"
		print "Saving... "
		page.save
		print "done!\n\n"
	rescue
		failcounter+=1
		if failcounter<5
			print "#{failcounter}th error, retrying!\n" 
			redo
		else
			print "#{failcounter}th error!\n\n"
			next
		end
	end
end

print 'Finished! Press any key to close.'
gets