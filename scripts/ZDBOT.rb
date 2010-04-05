require 'sunflower-core.rb'
require 'sunflower-commontasks.rb'
s=Sunflower.new
s.login

$summary='archiwizacja zadań'

pp=Page.get('Wikipedia:Zadania dla botów')
tasks=pp.text

tasksDone=[]
tasksError=[]
tasksOld=[]

tasks=tasks.gsub(/\n==\s*(.+?)\s*==\s*\{\{\/Status\|([^}]+)\}\}([\s\S]+?)(?=\r?\n==|\s*\Z)/) do
	title=$1.strip
	status=$2.strip
	text=$3.strip
	
	bval=''
	
	if (['wykonane','zrobione','błąd','błędne','stare'].index(status)==nil)
		bval=$&
	elsif (status=='wykonane' || status=='zrobione')
		tasksDone<<"== "+title+" ==\n{{/Status|"+status+"}}\n"+text
	elsif (status=='błąd' || status=='błędne')
		tasksError<<"== "+title+" ==\n{{/Status|"+status+"}}\n"+text
	elsif (status=='stare')
		tasksOld<<"== "+title+" ==\n{{/Status|"+status+"}}\n"+text
	end
	
	bval
end

puts 'Data loaded. Saving...'

p=Page.get('Wikipedia:Zadania_dla_botów/Archiwum/błędne')
p.append tasksError.join("\n\n") unless tasksError.empty?
p.save unless tasksError.empty?
puts 'Error - saved.'

p=Page.get('Wikipedia:Zadania_dla_botów/Archiwum/wykonane')
p.append tasksDone.join("\n\n") unless tasksDone.empty?
p.save unless tasksDone.empty?
puts 'Done - saved.'

p=Page.get('Wikipedia:Zadania_dla_botów/Archiwum/stare')
p.append tasksOld.join("\n\n") unless tasksOld.empty?
p.save unless tasksOld.empty?
puts 'Old - saved.'

pp.text=tasks
pp.save
puts 'Main - saved.'

# File.open('ZDBOT_main.txt','w').write(tasks)
# File.open('ZDBOT_done.txt','w').write(tasksDone.join("\n\n")) unless tasksDone.empty?
# File.open('ZDBOT_error.txt','w').write(tasksError.join("\n\n")) unless tasksError.empty?
# File.open('ZDBOT_old.txt','w').write(tasksOld.join("\n\n")) unless tasksOld.empty?

puts "Stats: done: #{tasksDone.length}; error: #{tasksError.length}; old: #{tasksOld.length}"
gets