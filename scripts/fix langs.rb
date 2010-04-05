require 'sunflower-commontasks.rb'
require 'sunflower-listmaker.rb'

# EDIT WIKI URL BELOW
s=Sunflower.new('pl.wikipedia.org')

print "Logging in to #{s.wikiURL}... "
# EDIT USERNAME AND PASSWORD BELOW
s.login
print "done!\n"

print "Reading articles list... "
# EDIT FILENAME BELOW
list=s.make_list('category', 'Kategoria:Nierozpoznany kod języka w szablonie lang')
print "done!\n\n"

# EDIT SUMMARY BELOW
$summary='dr.tech.'

list.each do |title|
	print "Reading page #{title}... "
	page=Page.get(title)
	print "done.\n"
	print "Modifying... "

	page.replace(/(\{\{cytuj [^\}]+?\|\s*język\s*=\s*|\{\{(?:multi|)lang\|)(angielskim?|eng?lish|ang\.|ang|eng?\.|eng|\[\[(?:język |)angielski[^\]]*\]\])/i, '\1en')
	page.replace(/(\{\{cytuj [^\}]+?\|\s*język\s*=\s*|\{\{(?:multi|)lang\|)(polskim?|pol\.|pol|pl\.|\[\[(?:język |)polski[^\]]*\]\])/i, '\1pl')
	page.replace(/(\{\{cytuj [^\}]+?\|\s*język\s*=\s*|\{\{(?:multi|)lang\|)(rosyjskim?|r[uo]s\.|r[uo]s|\[\[(?:język |)rosyjski[^\]]*\]\])/i, '\1ru')
	page.replace(/(\{\{cytuj [^\}]+?\|\s*język\s*=\s*|\{\{(?:multi|)lang\|)(cz)/i, '\1cs')
	page.replace(/(\{\{cytuj [^\}]+?\|\s*język\s*=\s*|\{\{(?:multi|)lang\|)(dk)/i, '\1da')
	page.replace(/(\{\{cytuj [^\}]+?\|\s*język\s*=\s*|\{\{(?:multi|)lang\|)(nb)/i, '\1no')
	page.replace(/(\{\{cytuj [^\}]+?\|\s*język\s*=\s*|\{\{(?:multi|)lang\|)(jp)/i, '\1ja')
	page.replace(/(\{\{cytuj [^\}]+?\|\s*język\s*=\s*|\{\{(?:multi|)lang\|)(greka|greckim?|gr\.?|eleka|eleckim?)/i, '\1el')
	#page.text=page.text.gsub(/(\{\{cytuj [^\}]+?\|\s*język\s*=\s*|\{\{(?:multi|)lang\|)([^\}\|]+)/i){$1+$2.downcase.split(/[^a-z-]+/).join('{{!}}')}
	
	print "done.\n"
	print "Saving... "
	page.save unless page.orig_text.downcase==page.text.downcase
	print "done!\n\n"
end

print 'Finished! Press any key to close.'
gets