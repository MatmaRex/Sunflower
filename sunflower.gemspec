Gem::Specification.new do |s|
  s.name = "sunflower"
  s.version = "0.4"
  s.date = "2012-03-03"
  s.authors = ["Matma Rex"]
  s.email = "matma.rex@gmail.com"
  s.homepage = "http://github.com/MatmaRex/Sunflower"
  s.summary = "Sunflower is a lightweight library to provide access to MediaWiki API from Ruby."
  s.description = "Sunflower is a lightweight library to provide access to MediaWiki API from Ruby."
	
	
	s.add_dependency 'json'
	s.add_dependency 'rest-client'
	
	s.executables = ['sunflower-setup']
	s.require_path = "lib"
	s.bindir = "bin"
	
  s.files = %w[
		README
		LICENSE
		bin/sunflower-setup
		example-bot.rb
		use-easy-bot.rb
		lib/sunflower.rb
		lib/sunflower/core.rb
		lib/sunflower/commontasks.rb
		lib/sunflower/listmaker.rb
		scripts/fix-bold-in-headers.rb
		scripts/fix-multiple-same-refs.rb
		scripts/fix-langs.rb
		scripts/lekkoatl-portal.rb
		scripts/ZDBOT.rb
		scripts/aktualizacjapilkarzy.rb
		scripts/changeimage.rb
		scripts/insight.rb
		scripts/make-id2team-list.rb
		scripts/author-list.rb
		scripts/fix-unicode-control-chars.rb
		scripts/fix-double-pipes.rb
		scripts/fix-some-entities.rb
		scripts/recat.rb
		scripts/wanted.rb
	]
end
