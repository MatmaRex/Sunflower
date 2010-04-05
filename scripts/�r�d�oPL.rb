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
list=s.make_list('file', 'list.txt')
print "done!\n\n"

# EDIT SUMMARY BELOW
$summary='przenosiny szablonu {{źródłoPL}}, [[WP:SK]]'
$wat=File.open('wat.txt','w')
$shiii=false

def fixme(digit,page)
	d=digit.to_i
	return 'bdr' if d==1
	return 'bdr' if d==21
	return 'regioset' if d==6
	return 'hydronimy1' if d==7
	return 'hydronimy2' if d==8
	return 'gus1' if d==12
	return 'pkw2006' if d==15
	return 'pkw2007' if d==25
	return 'dzu' if d==26
	return 'gus2' if d==28
	return 'gus3' if d==29
	return 'bobrowice' if d==30
	return 'wspólnota' if d==31
	return 'gus4' if d==32
	return 'gus5' if d==33
	return 'pkw2009' if d==34
	return 'gus6' if d==35

	
	$wat.write "# [[#{page.title}]] - #{digit}\n"
	$wat.flush
	$shiii=true
end

list.each do |title|
	print "Reading page #{title}... "
	page=Page.get(title)
	print "done.\n"
	print "Modifying... "

	page.replace("\r\n", "\n")	
	
	oldp=page.text
	page.write( page.text.gsub(/\{\{.{1,4}r.{1,4}d.{1,4}oPL\|(\d+)\}\}/i){"<ref name=\"pl-#{fixme $1,page}\">{{źródło PL|#{fixme $1,page}}}</ref>"} )
	
	if $shiii
		$shiii=false
		puts 'wrong number.'
		next
	end
	
	if oldp==page.text
	
		s.log '======================================'
		s.log oldp
		s.log '======================================'
		s.log page.text
	
	
		puts 'onoes'
		next
	end
	
	30.times{page.replace(/<ref name="pl-([^"]+)">(.+?)<\/ref>([\s\S]+)<ref name="pl-\1">\2<\/ref>/, '<ref name="pl-\1">\2</ref>\3<ref name="pl-\1" />')}
	
	
	
	page.replace(/(\{\{DEFAULTSORT|\[\[(?:Kategoria|Category))/i, "{{Przypisy}}\n\n\\1",1) if page.text.index(/\{\{Przypisy|<references/i)==nil
	
	page.codeCleanup
	
	
	
	print "done.\n"
	print "Saving... "
	page.save
	print "done!\n\n"
end

print 'Finished! Press any key to close.'
gets