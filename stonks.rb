require "pry"
require "date"
require "httparty"
require "csv"

# puts "STONKS!"

BASE_URL = "https://api.pushshift.io/reddit/search/"

ticker_table = CSV.parse(File.read("nyse.csv"), headers: true)
ALL_TICKERS = ticker_table.map{|ticker_row| ticker_row["Symbol"]}
# ALL_TICKERS = ["GME", "AMC", "BB", "NOK", "AAL"]

time_query = "&after=24h"

def fetch(ticker, time_query, comments = false)
    type = comments ? "comment/?q=" : "submission/?q="
    url = "#{BASE_URL}#{type}#{ticker}#{time_query}&metadata=true&size=1&sort_by=created_utc&sort=desc"
    # puts url
    HTTParty.get(url)
end

def most_recent(api_response)
    utc = api_response["data"][0]["created_utc"] unless !api_response["data"]
    puts Time.at(utc) unless !utc
end

def print_first_result(response)
    puts response["data"][0]["subreddit"]
    puts response["data"][0]["title"]
    puts response["data"][0]["selftext"]
end

def get_daily_change(ticker, comments = false)
    i = 1
    while i <= 30 do
        time_query = "&after=#{i}w&before=#{i - 1}w"
        response = fetch(ticker, time_query, comments)

        if response["metadata"]
            results = response["metadata"]["total_results"]
            date = (Date.today - (i * 7))
            puts "#{ticker} #{date}: #{results}"
            i += 1
        else
            puts "Retrying..."
        end
        
        sleep 0.3
    end
end

def fetch_posts(ticker, time_query)
    response = HTTParty.get("#{BASE_URL}#{ticker}#{time_query}&metadata=true&size=100&sort_by=created_utc&sort=desc")
    results = response["metadata"]["total_results"] unless !response["metadata"]
    puts "#{ticker} Posts: #{results}"
    # if (response["data"].length > 0)
    #     print_first_result(response)
    # end
    sleep 0.75
end

def fetch_comments(ticker, time_query)
    response = HTTParty.get("https://api.pushshift.io/reddit/search/comment/?q=#{ticker}#{time_query}&metadata=true&size=1&sort_by=created_utc&sort=desc")
    results = response["metadata"]["total_results"] unless !response["metadata"]
    puts "#{ticker} Comments: #{results}"
    sleep 0.75
end

def fetch_all_posts(time_query)
    ALL_TICKERS.each do |ticker|
        fetch_posts(ticker, time_query)
        # get_daily_change(ticker, time_query)
    end
end

def fetch_all_comments(time_query)
    ALL_TICKERS.each do |ticker|
        fetch_comments(ticker, time_query)
    end
end

# fetch_all_posts(time_query)
for arg in ARGV
    get_daily_change(arg, true)
end
# fetch_all_comments("&after=12h")

# for arg in ARGV
#     puts arg
#  end

# If we want to compare day to day, we'll need to store results in a database.
# Another option would be to just use "before" queries