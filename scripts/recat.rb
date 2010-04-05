require 'sunflower-commontasks.rb'
require 'sunflower-listmaker.rb'

from='Warhammer 40000'
to='Warhammer 40.000'

s=Sunflower.new
s.login
print "Logged in!\n"

print "Reading articles list... "
list=s.make_list('category-r', 'Kategoria:'+from).sort
print "done!\n\n"

# EDIT SUMMARY BELOW
$summary='zmiana nazewnictwa: Warhammer 40000 -> 40.000, [[WP:SK]]'

list.each do |title|
	print "Reading page #{title}... "
	page=Page.get(title)
	print "modifying... "

	page.codeCleanup
	page.changeCategory from, to
	
	print "saving... "
	page.save
	print "done!\n\n"
end

print 'Finished! Press any key to close.'
gets