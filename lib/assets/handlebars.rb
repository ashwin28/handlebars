require 'open-uri'
require 'nokogiri'

# send a request with the given url, returns [full_string, status]
def fetch_url_as_string(url)
  full_string = ""
  # add bad request to status for now
  status = ['400', 'Bad Request']

  begin
    open(url) do |f|
      # gets the status codes
      status = f.status
      # get the whole page as a string
      full_string = f.read
    end
  # handle http related errors
  rescue OpenURI::HTTPError => error
    # gets the status codes
    status = error.io.status rescue ['400', 'Bad Request']
    # get the whole page as a string
    full_string = error.io.string rescue ""
  # handle other relevent errors
  rescue => e
  end
  # return the full page string or an empty string depending on error and the status
  [full_string, status]
end

# ... From research ...
# twitter handles are of the following @[a-zA-Z0-9_]{1,15}
# they are unique and case insensitive
#
# ... Relevent source text ...
# A Twitter username may be no longer than 15 characters; when creating it,
# you're restricted to using just letters, numbers and underscores. For example,
# "JaneDoe," "JaneDoe10" and "Jane_Doe" will all work, but "Jane.Doe" or "Jane-Doe"
# will not. Although you can use capital letters in your name and your profile will
# display your username with the capitalization you choose, Twitter usernames aren't
# case sensitive. In other words, you can be "JohnSmith," "johnsmith" or any other
# variation you can imagine, but all variations will point to the same profile,
# and if somebody else has already registered one one of them, you'll be unable to
# use any.

# given a string, it returns an array unique of twitter handles found
def parse_relevent_handles(string)
  # return empty array if there is nothing to parse
  return [] if string.empty?

  # remove tags and remove emails
  # VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
  # which is taken from michael hartl's rails book
  # gsub '..//twitter.com/' => ' @' to account for hiddden handles inside href
  first_filter = string.gsub(/<\w*>*|<*\/*\w*>/, '').gsub(/\/\/(www.)*twitter.com\//, ' @')
                       .gsub(/[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+/i, '')

  # split by space, since handles cannot include space and filter by including @
  second_filter = first_filter.split().select { |s| s.include?('@') }
  
  # adhere to twitter standards and downcase for consistency
  possible_handles = second_filter.map { |e| e.scan(/@[0-9a-z_]+/i).map(&:downcase) }

  # remove nil values, duplicates, nested arrays and only return valid twitter names
  possible_handles.flatten.compact.uniq.select { |e| e.length <= 16 }
end

# given a twitter handle, it sends a search request to twitter, gets relavent info
# and returns a hash of values
def verify_handle(handle)
  search_url = "https://twitter.com/#{handle[1..-1]}"

  full_string, status = fetch_url_as_string(search_url)

  # if the twitter profile exists return relavent info
  # ProfileHeaderCard-name is as a css class test for existing user
  if status.first == '200' && full_string.include?('ProfileHeaderCard-name')
    get_relevent_user_info(full_string)
  # profile could not be found, return bad handle
  else
    handle
  end
end

# given an array of handles, it returns { good: {}, bad: [] }
def validate_handles(array)
  good = {}
  bad = []

  array.each do |i|
    result = verify_handle(i)
    # store respectivly
    result.instance_of?(Hash) ? good[result[:handle].to_sym] = result : bad << result
  end

  # return as hash
  { good: good, bad: bad }
end


# given a twitter page as a html string, return some user info
def get_relevent_user_info(string)
  doc = Nokogiri::HTML(string)
  # initial hash
  result = { handle: doc.at_css("div.ProfileCardMini-screenname span").text,
             profile_name: doc.at("h1.ProfileHeaderCard-name a").text }

  # add respective information if it's obtainable
  # needs to be checked every so often to ensure that it's finding the right elements
  if location = doc.at_css("span.ProfileHeaderCard-locationText")
    result[:location] = location.text.strip if location.text =~ /\w/
  end

  if joined = doc.at_css("span.ProfileHeaderCard-joinDateText")
    result[:joined] = joined.text
  end

  if url = doc.at_css("span.ProfileHeaderCard-urlText a")
    result[:url] = url.attributes["title"].value if url.attributes["title"]
  end

  # the following will have format # description
  if tweets = doc.at_css("li.ProfileNav-item--tweets a")
    tweets = tweets.attributes["title"].value.split()
    result[tweets.last.downcase.to_sym] = tweets.first
  end

  if following = doc.at_css("li.ProfileNav-item--following a")
    following = following.attributes["title"].value.split()
    result[following.last.downcase.to_sym] = following.first
  end
  
  if followers = doc.at_css("li.ProfileNav-item--followers a")
    followers = followers.attributes["title"].value.split()
    result[followers.last.downcase.to_sym] = followers.first
  end

  if likes = doc.at_css("li.ProfileNav-item--favorites a")
    likes = likes.attributes["title"].value.split()
    result[likes.last.downcase.to_sym] = likes.first
  end

  # found a protected profile, can't display first tweet, 
  if first_tweet = doc.at_css("p.ProtectedTimeline-explanation")
    result[:tweet_title] = doc.at_css("h2.ProtectedTimeline-heading").text
    result[:tweet_text] = first_tweet.text.strip
  # get the first tweet
  elsif first_tweet = doc.at_css("p.TweetTextSize")
    name = doc.at_css("div.stream-item-header strong").text
    user = doc.at_css("div.stream-item-header span.username b").text
    timestamp = doc.at_css("div.stream-item-header span._timestamp").text
    result[:tweet_title] = "#{name} @#{user} * #{timestamp}"
    result[:tweet_text] = first_tweet.text.strip
  # found a profile with no tweets
  elsif first_tweet = doc.at_css("p.empty-text")
    result[:tweet_title] = "Still waiting on #{result[:handle]}'s Tweets!"
    result[:tweet_text] = first_tweet.text.strip
  end

  # return result hash
  result
end
