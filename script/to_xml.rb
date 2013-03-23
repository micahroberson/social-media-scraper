require 'json'
require "active_support/core_ext"

p "How many files to processs? (enter #file or all)"
numFiles = gets.chomp()
if numFiles == 'all'
	numFiles = 9999
else
	numFiles = numFiles.to_i
end

i = 0
Dir['../json/*.json'].each do |filename|
	i+=1
	if i > numFiles then break end
	
	timestamp = filename.gsub(/[\.json\/]/, "")
	p 'opened ' + timestamp + '.json'
	file = File.open(filename, "r")

	my_xml = JSON.load(file).to_xml(:root => timestamp)
	File.open('../xml/' + timestamp + '.xml', 'w') do |f|
		f.write(my_xml)
	end
	p 'saved ' + timestamp + '.xml'
	file.close
end