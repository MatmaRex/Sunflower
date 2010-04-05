require 'sunflower-commontasks.rb'

s=Sunflower.new('pl.wikipedia.org')
s.login('Username','password')

$summary='Sunflower: test'
p=Page.get('asd')
p.write p.text+"\n\ntest"
p.save