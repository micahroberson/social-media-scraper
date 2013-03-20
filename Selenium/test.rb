@scrapeRetries = 3
def abc
	p "start test"
	for i in [3, 2, 0, 4]
		begin
			divide(i)
		rescue 
			p "error, retrying"
			divide(i + 1)
		end
	end
end

def divide(num)
	p 10 / num
end

def parseArgs
	$username = ARGV[0]
	$password = ARGV[1]
	if $username[0..1] == '--'
		$username = $username[2..$username.length]
	else
		raise "No username provided. Please use the syntax program.rb --username --password site1 site2.."
	end
	if $password[0..1] == '--'
		$password = $password[2..$password.length]
	else
		raise "No password provided. Please use the syntax program.rb --username --password site1 site2.."
	end
	$pages = ARGV[2..ARGV.length]
	
rescue 
	p "Please use the syntax program.rb --username --password site1 site2.."
end

parseArgs
p $username
p $password
p $pages


# $margs = [3, 2, 0, 4]

# for address in $margs
#   retries = 0
#   begin
#     p "Scraping " + address.to_s
#     divide(address)
#   rescue
#     until retries >= @scrapeRetries
#       begin
#         p "Scraping " + address
#         divide(address)
#         break
#       rescue
#         p "error with scrape, " + retries.to_s + " retries"
#         retries+=1
#       end
#     end
#   end
# end