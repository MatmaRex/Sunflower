require 'net/http'
require 'uri'
require 'cgi'
include Net

require 'sunflower-core.rb'
s=Sunflower.new
s.login

przejrzane=Page.new 'Wikipedysta:PMG/przejrzane'
t=przejrzane.read


begin
f=File.open('puredata.txt','r')
pd1=f.read.split(/\r?\n/)
f.close
rescue
pd1=[]
end

pdv=[]
pdn=[]
pd1.each do |i|
	n=i.split('|')
	n[1]='' if n[1]==nil
	
	pdn<<n[0]
	pdv<<n[1]
end

f=File.open('puredata.txt','w')

$counter=0
nt=t.sub(/(\{\| class="wikitable sortable"(?:\s*!.+)+)\s*\|-([\s\S]+?)(\|\})/){
	nl="\n" #shorten
	before=$1
	after=$3
	
	data=$2.split("|-\n|")
	data=data.map{|i|
		i.strip.split(/\s*\|\s*/)
	}
	
	data2=[]
	for d in data
		d.shift if d[0].strip==''
			
		# load puredata, if possible, and skip the rest
#		if pd[d[-1]]!=nil #&& pd[d[-1]]!=''
		i=pdn.index(d[-1])
		if i!=nil && pdv[pdn.index(d[-1])]!=nil
			puts d[-1]+':   (datafile)'
			puts '   '+pdv[i]
		
			last=d[-1]
			d[-1]=pdv[i]
			d<<last
			
			data2<<d
			$counter=0
			
			#rewrite puredata
			f.write(d[-1]+'|'+pdv[i]+nl)
			f.flush
			
			next #skip the rest of loop
		end
		
		url=d[0].sub(/^\*+ \[(http:[^ ]+) [^\]]+\]$/,'\1')
		
		#puts url
		puts d[-1]+':' if $counter==0
		
		begin
			res=HTTP.get(URI.parse(url.sub(/&category=([^&]+)/){'&category='+CGI.escape($1)}))
			
			f2=File.open('last.txt','w')
			f2.write(res)
			f2.close
			
			res=~/Znaleziono (\d+) nieprzejrza/
			num=$1
		rescue Timeout::Error
			num=nil
			$counter+=3 #repeat only once
		end
		
		if num==nil
			$counter+=1
			if $counter<5
				puts 'Retrying...'
				redo
			else
				num=''
			end
		end
		
		puts '   '+num
		
		last=d[-1]
		d[-1]=num
		d<<last
		
		data2<<d
		$counter=0
		
		#write puredata to file
		f.write(d[-1]+'|'+num+nl)
		f.flush
	end
	
	data3=nl
	for d in data2
		data3+='|-'+nl+'|'+d.join(nl+'|')+nl
	end
	
	months=%w(zero stycznia lutego marca kwietnia maja czerwca lipca sierpnia września października listopada grudnia)
	d=Date.parse(Time.now.to_s)
	
	before.sub(/(!Link do kategorii)/,'!'+d.day.to_s+' '+months[d.month]+' '+d.year.to_s+nl+'\1')+data3+after #print it out
}


f.close #puredata.txt

f=File.open('data2.txt','w')
f.write(nt)
f.close

$summary='aktualizacja'
przejrzane.write nt
przejrzane.save