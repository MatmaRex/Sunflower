require "algorithm/diff"
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
list=s.make_list('file', 'list2.txt')
print "done!\n\n"

# EDIT SUMMARY BELOW
$summary='usuwanie pogrubień z nagłówków, [[WP:SK]]'

list.each do |title|
	print "Reading page #{title}... "
	page=Page.get(title)
	print "done.\n"
	print "Modifying... "
	
	oldtxt=page.read

	page.replace(/(==+)\s*'''\s*(.+?)\s*'''\s*\1/, '\1 \2 \1') #simplest fix
	page.replace(/(==+)([^']*)'''([^']*)\1/, '\1\2\3\1') #broken bolds - opened, but not closed, remove them
	page.write page.text.gsub(/(==+)\s*(Znan.+? (?:osoby|ludzie) (?:nosz|o imien).+?)\s*\1/){h=$1; "#{h} #{$2.gsub("'''", '')} #{h}"} #pl.wiki specific
	page.write page.text.gsub(/(==+)\s*(.+?(?:\[\[imieniny\]\]|imieniny) obchodzi)\s*\1/){h=$1; "#{h} #{$2.gsub("'''", '')} #{h}"} #pl.wiki specific
	
	if oldtxt==page.read
		print "No changes.\n\n"
		next
	end
	
	page.codeCleanup
	
	# diffs = oldtxt.diff(page.read)
	
	# puts diffs
	# gets
	
	print "done.\n"
	print "Saving... "
	page.save
	print "done!\n\n"
end

print 'Finished! Press any key to close.'
gets