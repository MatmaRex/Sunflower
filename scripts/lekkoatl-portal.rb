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
# list=s.make_list('file', 'lekkoatl.txt')
# nice generating:
all=s.make_list('categoryr', 'Kategoria:Lekkoatletyka')
done=s.make_list('category', 'Kategoria:Wikiprojekt:Lekkoatletyka/hasła')
error=done.collect{|a| a.index ':'}
done=done.map{|a| (a.index ':' ? '' : 'Dyskusja:'+a)}
done.delete_if{|a| a==''}
list=all-done
print "done!\n\n"

File.open('err.txt','w'){|f| f.write error.join("\n")}
File.open('ok.txt','w'){|f| f.write list.join("\n")}

# EDIT SUMMARY BELOW
$summary='dodanie {{[[Portal:Lekkoatletyka/Info]]}}'

list.each do |title|
	print "Reading page #{title}... "
	page=Page.get('Dyskusja:'+title)
	print "done.\n"
	print "Modifying... "
	
	if page.text.index('Portal:Lekkoatletyka/Info')!=nil
		page.dump
		next
	end
	
	nl=(page.text.lstrip.index('{{')==0 ? "\n" : "\n\n")
	page.text='{{Portal:Lekkoatletyka/Info}}'+nl+page.text.lstrip
	
	print "done.\n"
	print "Saving... "
	page.save
	print "done!\n\n"
end

print 'Finished! Press any key to close.'
gets