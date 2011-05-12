# coding: utf-8

require 'sunflower.rb'
require 'pp'

s=Sunflower.new('pl.wikipedia.org')
print "Logging in to #{s.wikiURL}... "
#s.login
print "done!\n"

# EDIT SUMMARY BELOW
$summary='aktualizacja'




$all=File.open('wantedpages-20110211.txt', 'rb'){|f| f.read.force_encoding 'UTF-8'}.split(/\r?\n/).map{|ln| a=ln.split("\t"); a[1]=a[1].to_i; a}

puts "Lock'd and loaded"

def get a, b
   a,b=a.to_i, b.to_i
   $all.select{|name, count| count.between? a,b}.map{|name, count| "* [[#{name}]] - #{count}"}.join "\n"
end


ranges=[
  100..9999,
  50..99,
  40..49,
  30..39,
  25..29,
  22..24,
  20..21,
  18..19,
  16..17,
  15, 14, 13, 12, 11, 10,
  9, 8, 7, 6, 5
]

kat='A'

ranges.each do |rng|
  if rng.is_a?(Range) 
    a,b = rng.begin, rng.end
  else
    a,b = rng, rng
  end
  
  n="#{a}-#{b}"
  n="#{a}+" if b==9999
  n="#{a}" if b==a
  
  intro=<<EOF
Na tej stronie znajdują się najbardziej potrzebne strony, do których linki pojawiają się na #{n} stronach. Bazę utworzył Saper w lutym 2011 roku ([http://toolserver.org/~saper/wantedpages-20110211.txt pełna lista, ok. 37 MB]).

''Po prawej podana jest liczba dolinkowanych. Niebieskie linki do wycięcia. Czerwone do ewentualnego przenoszenia na podstrony [[Wikipedia:Brakujące hasła|brakujących haseł]].''

[[Kategoria:Najbardziej potrzebne strony| #{kat}]]
EOF
  
  title="Wikipedia:Propozycje tematów/Najbardziej potrzebne #{n} #{b==24 ? 'linki' : 'linków'}"
  
  File.open(n+'.txt', 'wb'){|f| f.write "#{intro}\n\n#{get a,b}"}
  
  
  kat=kat.succ
  
  
  puts n
end

