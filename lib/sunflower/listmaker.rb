# coding: utf-8
class Sunflower
	# Makes a list of articles. Returns array of titles.
	def make_list type, *parameters
		type=type.downcase.gsub(/[^a-z]/, '')
		first=parameters[0]
		firstE=CGI.escape first.to_s
		
		case type
		when 'file'
			f=File.open first
			list=f.read.sub(/\357\273\277/,'').strip.split(/\r?\n/)
			f.close
			
		when 'page', 'pages'
			list=parameters
			
		when 'categorieson'
			r = self.API_continued('action=query&prop=categories&cllimit=max&titles='+firstE, 'pages', 'clcontinue')
			list=r['query']['pages'].values.first['categories'].map{|v| v['title']}
			
		when 'category'
			r = self.API_continued('action=query&list=categorymembers&cmprop=title&cmlimit=max&cmtitle='+firstE, 'categorymembers', 'cmcontinue')
			list=r['query']['categorymembers'].map{|v| v['title']}
			
		when 'categoryr', 'categoryrecursive'
			list = [] # list of articles
			processed = []
			cats_to_process = [first] # list of categories to be processes
			while !cats_to_process.empty?
				now = cats_to_process.shift
				processed << now # make sure we do not get stuck in infinite loop
				
				list2 = self.make_list 'category', now # get contents of first cat in list
				
				 # find categories and queue them
				cats_to_process += list2
					.select{|el| el=~/\AKategoria:/}
					.reject{|el| processed.include? el or cats_to_process.include? el}
				
				list += list2 # add articles to main list
			end
			list.uniq!
			
		when 'linkson'
			r = self.API_continued('action=query&prop=links&pllimit=max&titles='+firstE, 'pages', 'plcontinue')
			list=r['query']['pages'].values.first['links'].map{|v| v['title']}
			
		when 'transclusionson', 'templateson'
			r = self.API_continued('action=query&prop=templates&tllimit=max&titles='+firstE, 'pages', 'tlcontinue')
			list=r['query']['pages'].values.first['templates'].map{|v| v['title']}
			
		when 'usercontribs', 'contribs'
			r = self.API_continued('action=query&list=usercontribs&uclimit=max&ucprop=title&ucuser='+firstE, 'usercontribs', 'uccontinue')
			list=r['query']['usercontribs'].map{|v| v['title']}
			
		when 'whatlinksto', 'whatlinkshere'
			r = self.API_continued('action=query&list=backlinks&bllimit=max&bltitle='+firstE, 'backlinks', 'blcontinue')
			list=r['query']['backlinks'].map{|v| v['title']}
			
		when 'whattranscludes', 'whatembeds'
			r = self.API_continued('action=query&list=embeddedin&eilimit=max&eititle='+firstE, 'embeddedin', 'eicontinue')
			list=r['query']['embeddedin'].map{|v| v['title']}
			
		when 'image', 'imageusage'
			r = self.API_continued('action=query&list=imageusage&iulimit=max&iutitle='+firstE, 'imageusage', 'iucontinue')
			list=r['query']['imageusage'].map{|v| v['title']}
			
		when 'search'
			r = self.API_continued('action=query&list=search&srwhat=text&srlimit=max&srnamespace='+(parameters[1]=='allns' ? CGI.escape('0|1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|100|101|102|103') : '0')+'&srsearch='+firstE, 'search', 'srcontinue')
			list=r['query']['search'].map{|v| v['title']}
			
		when 'searchtitles'
			r = self.API_continued('action=query&list=search&srwhat=title&srlimit=max&srnamespace='+(parameters[1]=='allns' ? CGI.escape('0|1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|100|101|102|103') : '0')+'&srsearch='+firstE, 'search', 'srcontinue')
			list=r['query']['search'].map{|v| v['title']}
		
		when 'random'
			r = self.API_continued('action=query&list=random&rnnamespace=0&rnlimit='+firstE, 'random', 'rncontinue')
			list=r['query']['random'].map{|v| v['title']}
			
		when 'external', 'linksearch'
			r = self.API_continued('action=query&list=exturlusage&eulimit=max&euprop=title&euquery='+firstE, 'exturlusage', 'eucontinue')
			list=r['query']['exturlusage'].map{|v| v['title']}
		
		when 'grep', 'regex', 'regexp'
			split=@wikiURL.split('.')
			ns=(parameters[1] ? parameters[1].to_s.gsub(/\D/,'') : '0')
			redirs=(parameters[2] ? '&redirects=on' : '')
			list=[]
			
			p=Net::HTTP.get(URI.parse("http://toolserver.org/~nikola/grep.php?pattern=#{firstE}&lang=#{split[0]}&wiki=#{split[1]}&ns=#{ns}#{redirs}"))
			p.scan(/<tr><td><a href="http:\/\/#{@wikiURL}\/wiki\/([^#<>\[\]\|\{\}]+?)(?:\?redirect=no|)">/){
				list<<CGI.unescape($1).gsub('_',' ')
			}
		end
		
		return list
	end
end

if $0==__FILE__
	puts 'What kind of list do you want to create?'
	if !(t=ARGV.shift)
		t=gets
	else
		t=t.strip
		puts t
	end
	puts ''
	
	puts 'Supply arguments to pass to listmaker:'
	puts '(press [Enter] without writing anything to finish)'
	arg=[]
	ARGV.each do |i|
		arg<<i.strip
		puts i.strip
	end
	while (a=gets.strip)!=''
		arg<<a
	end
	
	puts 'Making list, wait patiently...'
	
	s=Sunflower.new
	s.login
	
	l=s.make_list(t, *arg)
	l.sort!
	f=File.open('list.txt','w')
	f.write(l.join("\n"))
	f.close
	
	puts 'Done! List saved to "list.txt".'
end
