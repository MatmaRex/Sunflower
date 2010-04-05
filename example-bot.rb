# This is the most basic bot possible.

require 'sunflower-commontasks.rb'

s=Sunflower.new
s.login

$summary='Sunflower: test'

p=Page.get('Test')
p.write p.text+"\n\ntest"
p.save