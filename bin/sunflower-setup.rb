require 'sunflower'


path = Sunflower.path

puts "If you set your home wiki and userdata, you will not have to enter it in every script."
puts "Your userdata will be saved (IN PLAINTEXT!) in this file:"
puts "  #{path}"

puts ""

print "Enter your home wiki (for ex. en.wikipedia.org): "
home=gets.strip
puts ""

print "Enter your bot's nick on the home wiki: "
nick=gets.strip
puts ""

print "Enter your bot's password on home wiki (WILL BE SHOWN IN PLAINTEXT): "
pass=gets.strip
puts ""

worked = true
puts "Trying to connect with the data provided..."
begin
	s=Sunflower.new home
	s.login nick, pass
rescue
	worked = false
end

if worked
	puts "It seems to work!"
	puts "WARNING! USER DOES NOT HAVE BOT RIGHTS!" if !s.isBot?
else
	puts "Whoops, it didn't work. The error message is:"
	puts $!.message
end

save_them = worked

if !worked
	do
		print "Do you want to save the data anyway? [yn]"
		ans = gets.strip
	end until ans=~/[yn]/i
	
	save = (ans.downcase=='y')
end

if save
	f=File.open(path, "w")
	f.write "#{home.strip}\n#{nick.strip}\n#{pass.strip}"
	f.close
	
	puts "User data has been saved. Remember that your password is saved in plaintext!"
	puts ""

	puts "If you ever want to erase your login data, simply delete the file."
else
	puts "User data has not been saved. You can run this setup again anytime."
end
