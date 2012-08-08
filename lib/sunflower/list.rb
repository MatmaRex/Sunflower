# coding: utf-8

# Class representing a list of articles. Inherits from Array.
class Sunflower::List < Array
	# Create a new article list and fill it with items.
	# 
	# Sunflower may be nil; this will, however, make most methods unavailable.
	# 
	# This is in fact a wrapper for various list generator methods,
	# each private, named with the format of "list_<type>",
	# which accept the key and opts arguments and return arrays.
	# You can use this behavior to create your own ones.
	# 
	# You should probably use Sunflower#make_list instead of calling this directly.
	def initialize sunflower, type, key, opts={}
		@sunflower = sunflower
		
		meth = :"list_#{type}"
		if self.respond_to? meth, true
			super(self.send meth, key, opts)
		else
			raise Sunflower::Error, "no such list type available: #{type}"
		end
	end
	
	# Construct new list from an array.
	def self.from_ary ary, sunflower=nil
		Sunflower::List.new sunflower, 'pages', ary
	end
	
	
	# Converts self to an array of Sunflower::Page objects.
	# 
	# Use #pages_preloaded to preload the text of all pages at once, instead of via separate requests.
	def pages
		Array.new self.map{|t| Sunflower::Page.new t, @sunflower }
	end
	
	# Converts self to an array of Sunflower::Page objects,
	# then preloads the text in all of them using as little requests as possible.
	# (API limit is at most 500 pages/req for bots, 50 for other users.)
	# 
	# If any title is invalid, Sunflower::Error will be raised.
	# 
	# If any title is uncanonicalizable by Sunflower#cleanup_title,
	# it will not blow up or return incorrect results; however, text of some other
	# pages may be missing (it will be lazy-loaded when requested, as usual).
	def pages_preloaded
		pgs = self.pages
		at_once = @sunflower.is_bot? ? 500 : 50
		
		# this is different from self; page titles are guaranteed to be canonicalized
		titles = pgs.map{|a| a.title }
		
		titles.each_slice(at_once).with_index do |slice, slice_no|
			res = @sunflower.API('action=query&prop=revisions&rvprop=content&titles='+CGI.escape(slice.join '|'))
			res['query']['pages'].values.each_with_index do |h, i|
				page = pgs[slice_no*at_once + i]
				
				if h['title'] and h['title'] == page.title
					if h['missing']
						page.text = ''
					elsif h['invalid']
						raise Sunflower::Error, 'title invalid: '+page.title
					else
						page.text = h['revisions'][0]['*']
					end
					
					page.preloaded_text = true
				end
			end
		end
		
		return pgs
	end
	
	
private
	# Can be used to create a new list from array. Used internally in .from_ary.
	def list_pages ary, opts={} # :doc:
		ary
	end
	
	# Create from plaintext list, each title in separate line.
	def list_plaintext text, opts={} # :doc:
		text.split(/\r?\n/)
	end
	
	# Create from file. Supports BOM in UTF-8 files.
	def list_file filename, opts={} # :doc:
		lines = File.readlines(filename)
		lines[0].sub!(/^\357\273\277/, '') # BOM
		lines.each{|ln| ln.chomp! }
		lines.pop while lines.last == ''
		lines
	end
	
	# Categories on given page.
	def list_categories_on page, opts={} # :doc:
		r = @sunflower.API_continued('action=query&prop=categories&cllimit=max&titles='+CGI.escape(page), 'pages', 'clcontinue')
		r['query']['pages'].values.first['categories'].map{|v| v['title']}
	end
	
	# Category members.
	def list_category cat, opts={} # :doc:
		r = @sunflower.API_continued('action=query&list=categorymembers&cmprop=title&cmlimit=max&cmtitle='+CGI.escape(cat), 'categorymembers', 'cmcontinue')
		r['query']['categorymembers'].map{|v| v['title']}
	end
	
	# Category members. Scans categories recursively.
	def list_category_recursive cat, opts={} # :doc:
		list = [] # list of articles
		processed = []
		cats_to_process = [cat] # list of categories to be processes
		while !cats_to_process.empty?
			now = cats_to_process.shift
			processed << now # make sure we do not get stuck in infinite loop
			
			list2 = list_category now # get contents of first cat in list
			
			 # find categories and queue them
			cats_to_process += list2
				.select{|el| el =~ /^#{@sunflower.ns_regex_for 'category'}:/}
				.reject{|el| processed.include? el or cats_to_process.include? el}
			
			list += list2 # add articles to main list
		end
		list.uniq!
		return list
	end
	
	# Links on given page.
	def list_links_on page, opts={} # :doc:
		r = @sunflower.API_continued('action=query&prop=links&pllimit=max&titles='+CGI.escape(page), 'pages', 'plcontinue')
		r['query']['pages'].values.first['links'].map{|v| v['title']}
	end
	
	# Templates used on given page.
	def list_templates_on page, opts={} # :doc:
		r = @sunflower.API_continued('action=query&prop=templates&tllimit=max&titles='+CGI.escape(page), 'pages', 'tlcontinue')
		r['query']['pages'].values.first['templates'].map{|v| v['title']}
	end
	
	# Pages edited by given user.
	def list_contribs user, opts={} # :doc:
		r = @sunflower.API_continued('action=query&list=usercontribs&uclimit=max&ucprop=title&ucuser='+CGI.escape(user), 'usercontribs', 'uccontinue')
		r['query']['usercontribs'].map{|v| v['title']}
	end
	
	# Pages which link to given page.
	def list_whatlinkshere page, opts={} # :doc:
		r = @sunflower.API_continued('action=query&list=backlinks&bllimit=max&bltitle='+CGI.escape(page), 'backlinks', 'blcontinue')
		r['query']['backlinks'].map{|v| v['title']}
	end
	
	# Pages which embed (transclude) given page.
	def list_whatembeds page, opts={} # :doc:
		r = @sunflower.API_continued('action=query&list=embeddedin&eilimit=max&eititle='+CGI.escape(page), 'embeddedin', 'eicontinue')
		r['query']['embeddedin'].map{|v| v['title']}
	end
	
	# Pages which used given image.
	def list_image_usage image, opts={} # :doc:
		r = @sunflower.API_continued('action=query&list=imageusage&iulimit=max&iutitle='+CGI.escape(image), 'imageusage', 'iucontinue')
		r['query']['imageusage'].map{|v| v['title']}
	end
	
	# Search results for given text.
	# 
	# Options:
	# * ns: namespaces to search in, as pipe-separated numbers (or single number). Default: 0 (main).
	def list_search text, opts={} # :doc:
		opts = {ns: 0}.merge opts
		r = @sunflower.API_continued('action=query&list=search&srwhat=text&srlimit=max&srnamespace='+CGI.escape(opts[:ns].to_s)+'&srsearch='+CGI.escape(text), 'search', 'srcontinue')
		r['query']['search'].map{|v| v['title']}
	end
	
	# Search results for given text. Only searches in page titles. See also #list_grep.
	# 
	# Options:
	# * ns: namespaces to search in, as pipe-separated numbers (or single number). Default: 0 (main).
	def list_search_titles key, opts={} # :doc:
		opts = {ns: 0}.merge opts
		r = @sunflower.API_continued('action=query&list=search&srwhat=title&srlimit=max&srnamespace='+CGI.escape(opts[:ns].to_s)+'&srsearch='+CGI.escape(key), 'search', 'srcontinue')
		r['query']['search'].map{|v| v['title']}
	end
	
	# `count` random pages.
	def list_random count, opts={} # :doc:
		r = @sunflower.API_continued('action=query&list=random&rnnamespace=0&rnlimit='+CGI.escape(count.to_s), 'random', 'rncontinue')
		r['query']['random'].map{|v| v['title']}
	end
	
	# External link search. Format like on Special:LinkSearch.
	def list_linksearch url, opts={} # :doc:
		r = @sunflower.API_continued('action=query&list=exturlusage&eulimit=max&euprop=title&euquery='+CGI.escape(url), 'exturlusage', 'eucontinue')
		r['query']['exturlusage'].map{|v| v['title']}
	end
	
	# Pages whose titles match given regex. Uses nikola's grep tool: http://toolserver.org/~nikola/grep.php
	# 
	# Options:
	# * ns: namespace to search in, as a number (default: 0, main)
	# * redirs: whether to include redirects in search results (default: true)
	def list_grep regex, opts={} # :doc:
		opts = {ns: 0, redirs: true}.merge opts
		lang, wiki = @sunflower.wikiURL.split '.', 2
		
		list = []
		
		p = RestClient.get("http://toolserver.org/~nikola/grep.php?pattern=#{CGI.escape regex}&lang=#{CGI.escape lang}&wiki=#{CGI.escape wiki}&ns=#{CGI.escape opts[:ns].to_s}#{opts[:redirs] ? '&redirects=on' : ''}")
		p.scan(/<tr><td><a href="http:\/\/#{@sunflower.wikiURL}\/wiki\/([^#<>\[\]\|\{\}]+?)(?:\?redirect=no|)">/){
			list << @sunflower.cleanup_title($1)
		}
		return list
	end
end

class Sunflower
	# Makes a list of articles. Returns array of titles.
	def make_list type, key, opts={}
		begin
			return Sunflower::List.new self, type, key, opts
		rescue Sunflower::Error => e
			if e.message == "no such list type available: #{type}"
				backwards_compat = {
					:categorieson => :categories_on,
					:categoryrecursive => :category_recursive,
					:categoryr => :category_recursive,
					:linkson => :links_on,
					:templateson => :templates_on,
					:transclusionson => :templates_on,
					:usercontribs => :contribs,
					:whatlinksto => :whatlinkshere,
					:whattranscludes => :whatembeds,
					:imageusage => :image_usage,
					:image => :image_usage,
					:searchtitles => :search_titles,
					:external => :linksearch,
					:regex => :grep,
					:regexp => :grep,
				}
				
				if type2 = backwards_compat[type.to_s.downcase.gsub(/[^a-z]/, '').to_sym]
					warn "warning: #{type} has been renamed to #{type2}, old name will be removed in v0.6"
					Sunflower::List.new self, type2, key, opts
				else
					raise e
				end
			else
				raise e
			end
		end
	end
end
