puts "Fetching data at #{Time.now}!"

require "date"
require "httparty"
require "csv"
require "json"
require 'mail'


BASE_URL = "https://api.pushshift.io/reddit/search/"
ticker_table = CSV.parse(File.read("nyse.csv"), headers: true)
# ALL_TICKERS = ticker_table.map{|ticker_row| ticker_row["Symbol"]}
ALL_TICKERS = ["GME", "AMC", "BB", "NOK", "AAL"]

  $results = []
  $single_result = []

  def fetch(ticker, time_query, comments = false)
      type = comments ? "comment/?q=" : "submission/?q="
      url = "#{BASE_URL}#{type}#{ticker}#{time_query}&metadata=true&size=1&sort_by=created_utc&sort=desc"
      HTTParty.get(url)
  end

  def send_email(body)
    mail = Mail.new do
      from    'stonks@stonks.com'
      to      'ericschwartz7@gmail.com'
      subject 'Stonks'
      body     body
    end
    
    mail.deliver
  end

  def runner(ticker)
    # "posttype"=>"P", "after"=>"3", "before"=>"2", "timeincrement"=>"d", "ticker"=>"amc"
      # ticker = params["ticker"]
      ticker = ticker
      # after = params["after"]
      after = '3'
      # before = params["before"]
      before = '2'
      # comments = params["posttype"] == "C"
      comments = true
      # time_increment = params["timeincrement"]
      time_increment = 'd'

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
      "#{ticker} #{date_time}: #{results}\n"
      # $single_result = [date_time, results].to_json
  end

  email_body = ""
  ALL_TICKERS.each do |ticker|
    email_body += runner(ticker)
  end
  send_email(email_body)