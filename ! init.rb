require 'sunflower'


puts 'Thanks for using Sunflower. You should set it up now.'

print 'Your home wiki (for ex. en.wikipedia.org): '
home=gets
until home.strip=~/^[\w-]+(\.[\w-]+)*\.[a-z]{2,6}$/
	print 'Invalid input. Try again: '
	home=gets
end
puts ''

print 'Your bot\'s nick on home wiki: '
nick=gets
puts ''

print 'Your bot\'s password on home wiki (WILL BE SHOWN IN PLAINTEXT): '
pass=gets
puts ''

f=File.open('userdata', 'w')
f.write "#{home.strip}\n#{nick.strip}\n#{pass.strip}"
f.close

puts 'userdata file has been saved. Remember that it contains your password saved in plaintext!'
puts ''

puts 'Trying to connect...'
s=Sunflower.new
s.login
puts 'It seems to work!'
puts ''

puts 'WARNING! USER DOES NOT HAVE BOT RIGHTS!' unless s.isBot?

print 'Setup finished! Press any key to close.'
gets