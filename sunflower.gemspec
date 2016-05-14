Gem::Specification.new do |s|
	s.name = "sunflower"
	s.version = "0.5.11"
	s.date = "2013-05-26"
	s.authors = ["Matma Rex"]
	s.email = "matma.rex@gmail.com"
	s.homepage = "https://github.com/MatmaRex/Sunflower"
	s.summary = "Lightweight library to provide MediaWiki API access"
	s.description = "Sunflower is a lightweight library to provide access to MediaWiki API from Ruby."
	s.licenses = ["CC-BY-SA-3.0"]
	
	s.add_dependency 'json'
	s.add_dependency 'rest-client'
	
	s.executables = ['sunflower-setup']
	s.require_path = "lib"
	s.bindir = "bin"
	
  s.files = %w[
		LICENSE
		bin/sunflower-setup
		example-bot.rb
		lib/sunflower.rb
		lib/sunflower/core.rb
		lib/sunflower/commontasks.rb
		lib/sunflower/list.rb
		scripts/fix-bold-in-headers.rb
		scripts/fix-langs.rb
		scripts/lekkoatl-portal.rb
		scripts/fix-unicode-control-chars.rb
		scripts/fix-double-pipes.rb
		scripts/fix-some-entities.rb
		scripts/recat.rb
	]
end
