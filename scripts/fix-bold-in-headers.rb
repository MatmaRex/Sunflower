# coding: utf-8

require 'sunflower'
s = Sunflower.new.login

url = 'http://toolserver.org/~sk/cgi-bin/checkwiki/checkwiki.cgi?project=plwiki&view=bots&id=44&offset=0&limit=2500'

print "Reading articles list... "
# EDIT FILENAME BELOW
str=Net::HTTP.get(URI.parse(url))
list=str[(str.index('<pre>')+5)...(str.index('</pre>'))].strip.split(/\r?\n/).uniq
print "done!\n\n"

# EDIT SUMMARY BELOW
s.summary='usuwanie pogrubień z nagłówków, [[WP:SK]]'

list.each do |title|
	print "Reading page #{title}... "
	page=Page.new(title)
	print "done.\n"
	print "Modifying... "
	
	oldtxt=page.text

	page.replace(/(==+)\s*'''\s*(.+?)\s*'''\s*\1/, '\1 \2 \1') #simplest fix
	page.replace(/(==+)([^']*)'''([^']*)\1/, '\1\2\3\1') #broken bolds - opened, but not closed, remove them
	page.text = page.text.gsub(/(==+)\s*(Znan.+? (?:osoby|ludzie) (?:nosz|o imien).+?)\s*\1/){h=$1; "#{h} #{$2.gsub("'''", '')} #{h}"} #pl.wiki specific
	page.text = page.text.gsub(/(==+)\s*(.+?(?:\[\[imieniny\]\]|imieniny) obchodzi)\s*\1/){h=$1; "#{h} #{$2.gsub("'''", '')} #{h}"} #pl.wiki specific
	
	if oldtxt==page.text
		print "No changes.\n\n"
		next
	end
	
	page.code_cleanup
	
	print "done.\n"
	print "Saving... "
	page.save
	print "done!\n\n"
end
