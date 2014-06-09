# coding: utf-8
# This is the most basic bot possible.

require 'sunflower'

s = Sunflower.new.login
s.summary = 'test summary'

p = s.page 'Test'
p.text += "\n\ntest"
p.save
