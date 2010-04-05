require 'sunflower-commontasks.rb'
require 'sunflower-listmaker.rb'

image='Plik:Obiekt zabytkowy znak.svg'

# EDIT WIKI URL BELOW
s=Sunflower.new('pl.wikipedia.org')

print "Logging in to #{s.wikiURL}... "
# EDIT USERNAME AND PASSWORD BELOW
s.login
print "done!\n"

print "Reading articles list... "
# EDIT FILENAME BELOW
list=s.make_list('image', image).sort
print "done!\n\n"

# EDIT SUMMARY BELOW
$summary='podmiana grafiki, [[WP:SK]]'

list.each do |title|
	print "Reading page #{title}... "
	page=Page.get(title)
	print "done.\n"
	print "Modifying... "

	page.codeCleanup
	
	page.text.gsub!(/\[\[#{Regexp.escape image} *\|(?:left\||)[1-6]\dpx(?:\|left|)(\|[^\]\|]+|)\]\]( *(?:\r?\n|) *|)/) do
		next if $~[0].index('thumb') || $~[0].index('right')
		"[[Plik:Obiekt zabytkowy.svg|20px#{$1}]] "
	end
	
	print "done.\n"
	print "Saving... "
	page.save unless page.orig_text.downcase==page.text.downcase
	print "done!\n\n"
end

print 'Finished! Press any key to close.'
gets