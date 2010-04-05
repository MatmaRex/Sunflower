class Sunflower
	def make_list(type,*parameters)
	# makes list of articles
	# saves it to currentlist.txt
	# returns array of titles
		type=type.downcase.gsub(/[^a-z]/,'')
		first=parameters[0]
		firstE=CGI.escape(first)
		
		if type=='file'
			f=File.open(first)
			list=f.read.sub(/\357\273\277/,'').strip.split(/\r?\n/)
			f.close
			
		elsif type=='page' || type=='pages'
			list=parameters
			
		elsif type=='input'
			puts 'Insert titles of articles to edit:'
			puts 'Press [Enter] without inputting any text to finish.'
			puts 'Press [Ctrl]+[C] to kill bot.'
			list=[]
			while true
				input=gets.strip
				break if input==''
				
				list<<input
			end
			
		elsif type=='categorieson'
			r=self.API('action=query&prop=categories&cllimit=500&titles='+firstE)
			list=r['query']['pages'].first['categories'].map{|v| v['title']} #extract titles
			
		elsif type=='category'
			r=self.API('action=query&list=categorymembers&cmprop=title&cmlimit=5000&cmtitle='+firstE)
			list=r['query']['categorymembers'].map{|v| v['title']} #extract titles
			
		elsif type=='categoryr' || type=='categoryrecursive'
			list=[] #list of articles
			catsToProcess=[first] #list of categories to be processes
			while !catsToProcess.empty?
				list2=self.make_list('category',catsToProcess[0]) # get contents of first cat in list
				catsToProcess=catsToProcess+list2.select{|el| el=~/\AKategoria:/} # find categories in it and queue them to be processes
				catsToProcess.delete_at 0 # remove first category from list
				list=list+list2 #add articles to main list
			end
			list.uniq! #remove dupes
			
		elsif type=='linkson'
			r=self.API('action=query&prop=links&pllimit=5000&titles='+firstE)
			list=r['query']['pages'].first['links'].map{|v| v['title']} #extract titles
			
		elsif type=='transclusionson' || type=='templateson'
			r=self.API('action=query&prop=templates&tllimit=5000&titles='+firstE)
			list=r['query']['pages'].first['templates'].map{|v| v['title']} #extract titles
			
		elsif type=='usercontribs' || type=='contribs'
			r=self.API('action=query&list=usercontribs&uclimit=5000&ucprop=title&ucuser='+firstE)
			list=r['query']['usercontribs'].map{|v| v['title']} #extract titles
			
		elsif type=='whatlinksto' || type=='whatlinkshere'
			r=self.API('action=query&list=backlinks&bllimit=5000&bltitle='+firstE)
			list=r['query']['backlinks'].map{|v| v['title']} #extract titles
			
		elsif type=='whattranscludes' || type=='whatembeds'
			r=self.API('action=query&list=embeddedin&eilimit=5000&eititle='+firstE)
			list=r['query']['embeddedin'].map{|v| v['title']} #extract titles
			
		elsif type=='image' || type=='imageusage'
			r=self.API('action=query&list=imageusage&iulimit=5000&iutitle='+firstE)
			list=r['query']['imageusage'].map{|v| v['title']} #extract titles
			
		elsif type=='search'
			r=self.API('action=query&list=search&srwhat=text&srlimit=5000&srnamespace='+(parameters[1]=='allns' ? CGI.escape('0|1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|100|101|102|103') : '0')+'&srsearch='+firstE)
			list=r['query']['search'].map{|v| v['title']} #extract titles
			
		elsif type=='searchtitles'
			r=self.API('action=query&list=search&srwhat=title&srlimit=5000&srnamespace='+(parameters[1]=='allns' ? CGI.escape('0|1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|100|101|102|103') : '0')+'&srsearch='+firstE)
			list=r['query']['search'].map{|v| v['title']} #extract titles
		
		elsif type=='random'
			r=self.API('action=query&list=random&rnnamespace=0&rnlimit='+first.gsub(/\D/))
			list=r['query']['random'].map{|v| v['title']} #extract titles
			
		elsif type=='external' || type=='linksearch'
			r=self.API('action=query&euprop=title&list=exturlusage&eulimit=5000&euquery='+firstE)
			list=r['query']['exturlusage'].map{|v| v['title']} #extract titles
			
		elsif type=='google'
			limit=[parameters[1].to_i,999].min
			from=0
			list=[]
			
			while from<limit
				p=HTTP.get(URI.parse("http://www.google.pl/custom?q=kot&start=#{from}&sitesearch=#{@wikiURL}"))
				p.scan(/<div class=g><h2 class=r><a href="http:\/\/#{@wikiURL}\/wiki\/([^#<>\[\]\|\{\}]+?)" class=l>/){
					list<<CGI.unescape($1).gsub('_',' ')
				}
				
				from+=10
			end
		
		elsif type=='grep' || type=='regex' || type=='regexp'
			split=@wikiURL.split('.')
			ns=(parameters[1] ? parameters[1].to_s.gsub(/\D/,'') : '0')
			redirs=(parameters[2] ? '&redirects=on' : '')
			list=[]
			
			p=HTTP.get(URI.parse("http://toolserver.org/~nikola/grep.php?pattern=#{firstE}&lang=#{split[0]}&wiki=#{split[1]}&ns=#{ns}#{redirs}"))
			p.scan(/<tr><td><a href="http:\/\/#{@wikiURL}\/wiki\/([^#<>\[\]\|\{\}]+?)(?:\?redirect=no|)">/){
				list<<CGI.unescape($1).gsub('_',' ')
			}
		end
		
		return list
	end
	alias :makeList :make_list
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