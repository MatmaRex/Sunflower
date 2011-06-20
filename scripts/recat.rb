# coding: utf-8
require 'sunflower'

from = ''
to   = ''

s = Sunflower.new.login

print "Reading articles list... "
list=s.make_list('category', 'Kategoria:'+from).sort
print "done!\n\n"

s.summary = ''

list.each do |title|
	print "Reading page #{title}... "
	page=Page.get(title)
	print "modifying... "

	page.code_cleanup
	page.change_category from, to
	
	print "saving... "
	page.save
	print "done!\n\n"
end

