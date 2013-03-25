require 'json'
require "active_support/core_ext"
require 'csv'

$postSchema = ["text", "textTrimmed", "shares", "likeSentence", "likeCount", "commentSentence", "commentCount"]

p "How many files to processs? (enter #file or all)"
$numFiles = gets.chomp()
p "limit to a site? (type site name or NO)"
$filter = gets.chomp()
if $filter == "no" || $filter == "NO"
	$filter = ''
end

if $numFiles == 'all'
	$numFiles = 9999
else
	$numFiles = $numFiles.to_i
end

def trimPost(text)
	try = text.match(/.+(january|february|march|april|may|june|july|august|september|october|november|december)\s[0-9]+(.+)/i)
	if try ; return try[2] ; end
	try = text.match(/.+(yesterday|sunday|monday|tuesday|wednesday|thursday|friday|saturday)(.+)/i)
	if try ; return try[2] ; end
	try = text.match(/(.+ago)(.+)/i)
	if try ; return try[2] ; end
	return text
end



def csvParse(data)
	csvData = CSV.generate do |csv|
		postKeys = data[data.keys.first][data[data.keys.first].keys.last].keys
		csv << ['pull_time', 'site', 'post_id', 'people_talking', 'total_likes'] + $postSchema
		data.each do |site_name, site_data|
			if site_name != $filter then next end
			peopleTalking = data[site_name]["people_talking"]
			totalLikes = data[site_name]["total_likes"]

			data[site_name].each do |post_id, post_data|
				if [0, "0", "people_talking", "total_likes"].include? post_id ; next ; end
				csvRow = []
				$postSchema.each do |k|
					begin
						csvRow.push (post_data[k]) ? removeCommas(post_data[k]) : nil
					rescue
						p 'error'
						p k
					end
				end
				csvRow = checkRow(csvRow)
				csv << [$time.to_i, site_name, 'p'+post_id, peopleTalking, totalLikes] + csvRow
			end
		end
	end
	return csvData
end

def removeCommas(val)
	return (val.is_a? String) ? val.gsub(',', '') : val
end
def checkRow(row)
	likeSentence = row[$postSchema.index('likeSentence')]
	likeCount = row[$postSchema.index('likeCount')]
	commentSentence = row[$postSchema.index('commentSentence')]
	commentCount = row[$postSchema.index('commentCount')]
	if likeSentence && !likeCount
		likeCount = likeSentence.match(/[0-9]+/)
		likeCount = likeCount ? likeCount[0].to_i : ''
		row[$postSchema.index('likeCount')] = likeCount
	end
	if commentSentence && !commentCount
		commentCount = commentSentence.match(/[0-9]+\s*of\s*([0-9]+)/)
		commentCount = commentCount ? commentCount[1].to_i + 2 : (commentSentence.match(/([0-9]+)\s*more/))
		commentCount = commentCount ? commentCount[1].to_i + 2 : ''
		row[$postSchema.index('commentCount')] = commentCount
	end
	row[$postSchema.index('textTrimmed')] = trimPost(row[$postSchema.index('text')])
	return row
end

i = 0
Dir['../json/*.json'].each do |filename|
	i+=1
	if i > $numFiles then break end
	
	$timestamp = filename.gsub(/[\.json\/]/, "")
	$time = Time.new($timestamp[0..3], $timestamp[4..5], $timestamp[6..7], $timestamp[8..9], $timestamp[10..11])
	p 'opened ' + $timestamp + '.json'
	file = File.open(filename, "r")

	begin
		data = JSON.load(file)
		csvData = csvParse(data)
	# rescue
	# 	p "error with " + $timestamp + '.json, skipping'
	end

	File.open('../csv/' + $timestamp + '.csv', 'w') do |f|
		f.write(csvData)
	end
	p 'saved ' + $timestamp + '.csv'
	file.close
end

def ignore_this
	require 'json'
	require 'csv'
	file = File.open(Dir['../json/*.json'].last, "r")
	data = JSON.load(file)

	keys = data[data.keys.first][data[data.keys.first].keys.last].keys
end