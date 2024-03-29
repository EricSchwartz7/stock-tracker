# TO START >> ruby stonks.rb

require "pry-byebug"
require "date"
require "httparty"
require "csv"
require "sinatra"
require "sinatra/reloader"
require "json"
require "sinatra/cors"
require "sinatra/config_file"

config_file './config.yml'

set :allow_origin, "*"
set :allow_methods, "GET,HEAD,POST"
set :allow_headers, "content-type,if-modified-since"
set :expose_headers, "location,link"

BASE_URL = "https://api.pushshift.io/reddit/search/"
ticker_table = CSV.parse(File.read("nyse.csv"), headers: true)
ALL_TICKERS = ticker_table.map{|ticker_row| ticker_row["Symbol"]}
# ALL_TICKERS = ["GME", "AMC", "BB", "NOK", "AAL"]

get '/pushshift/:ticker' do
    $results = []
    $single_result = []

    def fetch(ticker, time_query, comments = false)
        type = comments ? "comment/?q=" : "submission/?q="
        url = "#{BASE_URL}#{type}#{ticker}#{time_query}&metadata=true&size=1&sort_by=created_utc&sort=desc"
        HTTParty.get(url)
    end

    def runner
      puts params.inspect
        ticker = params["ticker"]
        after = params["after"]
        before = params["before"]
        comments = params["posttype"] == "C"
        time_increment = params["timeincrement"]

        time_query = "&after=#{after}#{time_increment}&before=#{before}#{time_increment}"

        response = fetch(ticker, time_query, comments)
        results = response["metadata"]["total_results"] unless !response["metadata"]

        date_time = ""

        case time_increment
        when "w"
            date_time = (Date.today - (after.to_i * 7))
        when "d"
            date_time = (Date.today - after.to_i)
        when "h"
            hours = after.to_i
            date_time = (DateTime.now - (hours/24.0))
        when "m"
            minutes = after.to_i
            date_time = (DateTime.now - (minutes/1440.0))
        end

        puts "#{ticker} #{date_time}: #{results}"
        $single_result = [date_time, results].to_json
    end

    runner()
end

get '/access_token' do
    url = "https://www.reddit.com/api/v1/access_token"
    response = HTTParty.post(url, {
        body: {
            grant_type: "password",
            username: settings.reddit_username,
            password: settings.reddit_pw
        },
        basic_auth: {
            username: "NVagLjEmWr9PPQ",
            password: "iLGa4GNKc1UCtGs9dMpseRMhjB5x2g"
        },
        headers: {"User-Agent" => "HTTParty"}
    })
    puts "--------------------------------"
    puts response
    puts "--------------------------------"
    response["access_token"].to_json
end

get '/reddit/:ticker' do
    url = "https://oauth.reddit.com/search"
    response = HTTParty.get(url, 
        query: {
            q: params[:ticker],
            limit: 100,
            after: params[:after]
        },
        headers: {
            "Authorization" => "Bearer #{params[:token]}",
            "User-Agent" => "HTTParty"
        }
    )
    after = response["data"]["after"]
    puts "-----------------------"
    puts "Token: #{params[:token]}"
    puts after
    puts "-----------------------"
    response["data"].to_json    
end

# curl -X POST -d 'grant_type=password&username=[username]&password=[password]' --user '[token]' https://www.reddit.com/api/v1/access_token

# curl -H "Authorization: bearer [token]" -A "ChangeMeClient/0.1 by Ricsta76" https://oauth.reddit.com/api/v1/me


# time_query = "&after=24h"

    # def most_recent(api_response)
    #     utc = api_response["data"][0]["created_utc"] unless !api_response["data"]
    #     puts Time.at(utc) unless !utc
    # end

    # def print_first_result(response)
    #     puts response["data"][0]["subreddit"]
    #     puts response["data"][0]["title"]
    #     puts response["data"][0]["selftext"]
    # end

    # def get_posts_incrementally(ticker, comments = false)
    #     i = 1
    #     while i <= 5 do
    #         time_query = "&after=#{i}w&before=#{i - 1}w"
    #         response = fetch(ticker, time_query, comments)

    #         if response["metadata"]
    #             results = response["metadata"]["total_results"]
    #             date = (Date.today - (i * 7))
    #             i += 1
    #             result_string = "#{ticker} #{date}: #{results}"
    #             puts result_string
    #             $results.push([date, results])
    #         else
    #             puts "Retrying..."
    #             $results.push("Retrying...")
    #         end

    #         sleep 0.3
    #     end
    # end

    # def fetch_posts(ticker, time_query)
    #     response = HTTParty.get("#{BASE_URL}#{ticker}#{time_query}&metadata=true&size=100&sort_by=created_utc&sort=desc")
    #     results = response["metadata"]["total_results"] unless !response["metadata"]
    #     puts "#{ticker} Posts: #{results}"
    #     # if (response["data"].length > 0)
    #     #     print_first_result(response)
    #     # end
    #     sleep 0.75
    # end

    # def fetch_comments(ticker, time_query)
    #     response = HTTParty.get("https://api.pushshift.io/reddit/search/comment/?q=#{ticker}#{time_query}&metadata=true&size=1&sort_by=created_utc&sort=desc")
    #     results = response["metadata"]["total_results"] unless !response["metadata"]
    #     puts "#{ticker} Comments: #{results}"
    #     sleep 0.75
    # end

    # def fetch_all_posts(time_query)
    #     ALL_TICKERS.each do |ticker|
    #         fetch_posts(ticker, time_query)
    #         # get_posts_incrementally(ticker, time_query)
    #     end
    # end

    # def fetch_all_comments(time_query)
    #     ALL_TICKERS.each do |ticker|
    #         fetch_comments(ticker, time_query)
    #     end
    # end

    # fetch_all_posts(time_query)
    # for arg in ARGV
    #     get_posts_incrementally(arg, true)
    # end
    # fetch_all_comments("&after=12h")