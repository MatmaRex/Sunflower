require 'orderedhash'
require 'hpricot'
require 'net/http'
require 'sunflower-core.rb'
require 'sunflower-listmaker.rb'
include Net

$datafile=File.open('aktual.txt','w')
$datafile.sync=true

id2team={}
begin
	File.open('id2team.txt') do |f|
		id2team.replace Hash[*f.read.strip.split(/\r?\n|\t/)]
	end
rescue
end

# comes from http://rubyforge.org/frs/?group_id=6257&release_id=36721
module Levenshtein
  VERSION	= "0.2.0"

  # Returns the Levenshtein distance as a number between 0.0 and
  # 1.0. It's basically the Levenshtein distance divided by the
  # length of the longest sequence.

  def self.normalized_distance(s1, s2, threshold=nil)
    s1, s2	= s2, s1	if s1.length > s2.length	# s1 is the short one; s2 is the long one.

    if s2.length == 0
      0.0	# Since s1.length < s2.length, s1 must be empty as well.
    else
      if threshold
        if d = self.distance(s1, s2, (threshold*s2.length+1).to_i)
          d.to_f/s2.length
        else
          nil
        end
      else
        self.distance(s1, s2).to_f/s2.length
      end
    end
  end

  # Returns the Levenshtein distance between two sequences.
  #
  # The two sequences can be two strings, two arrays, or two other
  # objects. Strings, arrays and arrays of strings are handled with
  # optimized (very fast) C code. All other sequences are handled
  # with generic (fast) C code.
  #
  # The sequences should respond to :length and :[] and all objects
  # in the sequences (as returned by []) should response to :==.

  def self.distance(s1, s2, threshold=nil)
    s1, s2	= s2, s1	if s1.length > s2.length	# s1 is the short one; s2 is the long one.

    # Handle some basic circumstances.

    return 0		if s1 == s2
    return s2.length	if s1.length == 0

    if threshold
      return nil	if (s2.length-s1.length) >= threshold

      a1, a2	= nil, nil
      a1, a2	= s1, s2			if s1.respond_to?(:-) and s2.respond_to?(:-)
      a1, a2	= s1.scan(/./), s2.scan(/./)	if s1.respond_to?(:scan) and s2.respond_to?(:scan)

      if a1 and a2
        return nil	if (a1-a2).length >= threshold
        return nil	if (a2-a1).length >= threshold
      end
    end

    distance_fast_or_slow(s1, s2, threshold)
  end

  def self.distance_fast_or_slow(s1, s2, threshold)	# :nodoc:
    if respond_to?(:levenshtein_distance_fast)
      levenshtein_distance_fast(s1, s2, threshold)	# Implemented in C.
    else
      levenshtein_distance_slow(s1, s2, threshold)	# Implemented in Ruby.
    end
  end

  def self.levenshtein_distance_slow(s1, s2, threshold)	# :nodoc:
    row	= (0..s1.length).to_a

    1.upto(s2.length) do |y|
      prow	= row
      row	= [y]

      1.upto(s1.length) do |x|
        row[x]	= [prow[x]+1, row[x-1]+1, prow[x-1]+(s1[x-1]==s2[y-1] ? 0 : 1)].min
      end

      # Stop analysing this sequence as soon as the best possible
      # result for this sequence is bigger than the best result so far.
      # (The minimum value in the next row will be equal to or greater
      # than the minimum value in this row.)

      return nil	if threshold and row.min >= threshold
    end

    row[-1]
  end
end


def puts *arg
	arg.each{|str| $stdout.puts str; $datafile.puts str}
end

def saveData
=begin
	File.open('aktualdata.txt','w'){|f|
		f.write "
$notfound=#{$notfound.length}
$same=#{$same.length}
$diff=#{$diff.length}
----
$notfound:
# {$notfound.join "\n"}
----
$same:
# {$same.join "\n"}
----
$diff:
# {$diff.join "\n"}
"
	}
=end
end

def get(url)
	return HTTP.get(URI.parse(url))
end

def getPlayerData url
	r=get url
	r=~/<b>All time playing career<\/b>/
	r=$'
	r=~/<a name=games><\/a>/
	table=$`.strip
	
	h=Hpricot.parse table
	rows=h.search 'tr+tr'
	
	data={}
	rows.each do |r|
		if r.at('td')['colspan']==nil && (r.inner_html=~/No appearance data available/)==nil
			cells=r.search 'td'
			team=cells[0].search('font a')[0].inner_html.strip
			teamid=cells[0].search('font a')[0]['href'].sub(/\A.+?(\d+)\Z/, '\1')
			matches=cells[4].at('font').inner_html.split('(').map{|m| m.gsub(/[^0-9]/,'').to_i}
			matches=matches[0]+matches[1]
			goals=cells[5].at('font').inner_html.gsub(/[^0-9]/,'').to_i
			
			data[team]=[matches,goals,teamid]
		end
	end
	return data
end

def searchForPlayer text
	d=get "http://www.soccerbase.com/search.sd?search_string=#{CGI.escape text}&search_cat=players"
	d=~/window.location = "(http:[^"]+)"/
	
	return $1
end

$edits=0
$summary='aktualizacja danych o meczach piłkarza'

puts 'Making list...'
s=Sunflower.new('pl.wikipedia.org')
s.login
enw=Sunflower.new('en.wikipedia.org')
enw.login

# list=(
	# s.makeList('category-r', 'Kategoria:Piłkarze Aston Villa F.C.')+
	# s.makeList('category-r', 'Kategoria:Piłkarze Chelsea F.C.')+
	# s.makeList('category-r', 'Kategoria:Piłkarze Liverpool F.C.')
# ).uniq
# list=(
	# s.makeList('category-r', 'Kategoria:Piłkarze angielskich klubów')+
	# s.makeList('category-r', 'Kategoria:Piłkarze walijskich klubów')
# ).uniq

# list.delete_if{|i| i=~/^Kategoria:/}

# File.open('lista-pilkarze.txt','w').write list.join("\n")
# list=File.open('lista-pilkarze.txt').read.split(/\r?\n/)
list=['Wikipedysta:Matma Rex/brudnopis']

puts 'Done!'
puts ''

$notfound=[]
$same=[]
$diff=[]

list.each_with_index do |art, i|
	exit if $edits>4
	
	# finding data
	puts "* [[#{art}]]"
	pPl=Page.new(art, 'pl')
	pPl.read=~/\[\[en:([^\]]+)\]\]/
	if $1
		artEn=$1
		puts "** Interwiki-en: [[:en:#{artEn}]]"
	else
		artEn=art
		puts "** No interwiki; guessing [[:en:#{art}]]"
	end
	
	pPl.read=~/\{\{soccerbase.*?(\d+).*?\}\}|soccerbase\.com\/players_details\.sd\?playerid=(\d+)/i
	if $1||$2
		soccid=$1||$2
		url="http://www.soccerbase.com/players_details.sd?playerid=#{soccid}"
		puts '** Found id on plwiki'
	else
		pEn=Page.new(art, 'en')
		pEn.read=~/\{\{soccerbase.*?(\d+).*?\}\}|soccerbase\.com\/players_details\.sd\?playerid=(\d+)/i
		if $1||$2
			soccid=$1||$2
			url="http://www.soccerbase.com/players_details.sd?playerid=#{soccid}"
			puts '** Found id on enwiki'
		else
			url=searchForPlayer(art)||searchForPlayer(artEn)
		end
	end
	
	if url==nil
		puts '** Not found.'
		$notfound<<art
	else
		data=getPlayerData url
		puts "** URL: #{url}"
		unless data.empty?
			puts "** Found info on soccerbase."
		else
			puts '** Found, but no data.'
			$notfound<<art
		end
	end
	
	pPl.read =~ /występy\(gole\)\s*=(.+)/
	if $1==nil
		puts '** Wiki: error. No infobox?'
	else
		a=$1.split(/\s*<br.*?>\s*/)[-1].strip
		a=~/(\d+)\s*\((\d+)\)/
		matchesW, goalsW = $1.to_i, $2.to_i
		puts "** Wiki info:  #{matchesW} matches, #{goalsW} goals."
	end
	
	saveData if i%30==0 && i!=0
		
	# $change=File.open('changelist.txt','w')
	# $change.sync=true
	
	# editing
	if data
		#$change.puts "* [[#{art}]] - #{matchesW}/#{goalsW} -> #{matches}/#{goals}"
		
		pPl.text=~/(kluby\s*=\s*)([^\|]+)(\s*\|)/
		kluby=$2
		pPl.text=~/(występy\(gole\)\s*=\s*)([^\|]+)(\s*\|)/
		wystepygole=$2
		
		resolve={}
		kluby=kluby.split(/<\/?br[^>]*>/).map do |i|
			short=i.strip.gsub(/\[\[(?:[^\]\|]+\||)([^\]\|]+)\]\]/,'\1').gsub(/→|\(wyp\.\)/,'').strip
			resolve[short]=i.strip
			short
		end
		wystepygole=wystepygole.split(/<\/?br[^>]*?>/).map{|i| i.strip}
		wystepygole.delete_if{|i| i==''}
		kluby.delete_if{|i| i==''}
		
		wystepygole.pop while wystepygole.length>kluby.length
		wystepygole.push [0,0] while wystepygole.length<kluby.length
		
		wikidata=OrderedHash.new
		kluby.each_index do |i|
			wystepygole[i]=~/(\d+)\s*\((\d+)\)/
			wikidata[kluby[i]]=[$1.to_i, $2.to_i]
		end
		
		# puts data.inspect
		# puts wikidata.inspect
		
		data.each_pair do |scbclub, scb, teamid|
			min=[999, 'null']
			wikidata.each_pair do |wikiclub, wiki|
				if wikiclub.index scbclub || scbclub.index wikiclub
					min=[0, wikiclub] 
					break
				end
				if wikiclub.index id2team[teamid] || id2team[teamid].index wikiclub
					min=[0, wikiclub] 
					break
				end
				
				d=Levenshtein.distance(scbclub, wikiclub)
				min=[d, wikiclub] if d<min[0]
				
				d=Levenshtein.distance(id2team[teamid], wikiclub)
				min=[d, wikiclub] if d<min[0]
			end
			club=min[1]
			
			wikidata[club]=data[scbclub]
		end
		
		infoboxwystepygole=[]
		infoboxkluby=[]
		
		wikidata.each do |club, info|
			infoboxkluby<<resolve[club]
			infoboxwystepygole<<"#{info[0]} (#{info[1]})"
		end
		
		infoboxkluby=infoboxkluby.join('<br />')
		infoboxwystepygole=infoboxwystepygole.join('<br />')
				
		pPl.text=pPl.text.sub(/(występy\(gole\)\s*=\s*)([^\|]+?)(\s*\|)/){$1+infoboxwystepygole+$3}		
		pPl.text=pPl.text.sub(/(kluby\s*=\s*)([^\|]+?)(\s*\|)/){$1+infoboxkluby+$3}		
		pPl.text=pPl.text.sub(/(data1\s*=\s*)([^\|]+?)(\s*\|)/, '\1{{subst:CURRENTDAY}} {{subst:CURRENTMONTHNAMEGEN}} {{subst:CURRENTYEAR}}\3')
		
		$edits+=1
		pPl.save
	end
end

