#my Twilio number: (614) 972-1846
require 'twilio-ruby'
require 'rickmorty'
require 'httparty'

greetings = ["Hi", "Hello", "What up", "Yo"]
morning = ["Morning", "Good morning"]
afternoon = ["Afternoon", "Good afternoon"]
evening = ["Evening", "Good evening"]

#a secret code for signup #
code = "R2D2"

require 'sinatra'
require "sinatra/reloader" if development?


enable :sessions

configure :development do
  require 'dotenv'
  Dotenv.load
end

get '/' do
	redirect to "/about"
end


get "/about" do
	session["visits"] ||= 0 # Set the session to 0 if it hasn't been set before
  session["visits"] = session["visits"] + 1  # adds one to the current value (increments)

	time = Time.now #returns the time today
	hour = time.hour
	time = time.strftime("%A %B %d, %Y %H:%M") # gives: Tuesday October 01, 2017 02:02

  ### BONUS - Customize greetings to AM / PM
	if hour > 0 && hour < 12
		greet = morning.sample
	elsif hour > 12 && hour < 17
		greet = afternoon.sample
	else
		greet = evening.sample
	end


	if session[:first_name].nil?
		greet + " new friend! My MeBot is a minimal-interface bot who tells you about the weather today and
		clothes recommendation. <br/>You have visited " + session["visits"].to_s +
		" times as of " + time.to_s
	else
		greet + " " + session[:first_name] + "! My MeBot is a minimal-interface bot who tells you about the weather today and
		clothes recommendation. <br/>You have visited " + session["visits"].to_s +
		" times as of " + time.to_s
	end
end

########################### bug part 7 #######################################
get "/signup" do
	if params[:code] == code
		erb :signup
	else
		403
	end

end


#bug
post "/signup" do
  # we'll add some code here
	# code to check parameters
	client = Twilio::REST::Client.new ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"]

	# Include a message here
	 message = "Hi" + params[:first_name] + ", welcome to MeBot! I can respond to who, what, where, when and why. If you're stuck, type help."

	# this will send a message from any end point
	client.api.account.messages.create(
		from: ENV["TWILIO_FROM"],
		to: params[:number],
		body: message
	)
	# response if eveything is OK
	"You're signed up. You'll receive a text message in a few minutes from the bot. "

	# if params[:code] == code
	# 	if params[:name]=="" || params[:number]==""
  #     "Your information is incompelete, please input again!"
  #   else
  #     session[:name] = params['first_name']
  #     session[:number] = params['number']
  #     session[:visits] = 0
  #     time = Time.now
  #     "Welcome! #{session[:name]}! My app dose Blablablabla.
  #     You will receive a text message in a few minutes from the bot."
  #   end
  # else
  #   403
  # end
end
########################### bug part 7 #######################################



get "/sms/incoming" do
  session["counter"] ||= 1
  body = params[:Body] || "hiiiiiiiii"
	sender = "Qicheng"

  if session["counter"] == 1
     message = "Thanks for your first message. From #{sender} saying #{body}"
    # media = "https://media.giphy.com/media/13ZHjidRzoi7n2/giphy.gif"
		media = "https://media.giphy.com/media/5GdhgaBpA3oCA/giphy.gif"
  else
    message = determine_response body
    media = nil
  end

	# Build a twilio response object
  twiml = Twilio::TwiML::MessagingResponse.new do |r|
    r.message do |m|

			# add the text of the response
      m.body(message)

			# add media if it is defined
      unless media.nil?
        m.media(media)
      end
    end
  end

	# increment the session counter
  session["counter"] += 1

	# send a response to twilio
  content_type 'text/xml'
  twiml.to_s

end



get "/test/conversation" do
	#set 2 expected variables
	body = params[:Body]
	from = params[:From]

	#check if both variables are populated
	if body.nil?
		 return "I don't see your Body.Check your URL for a correct Body input!"
	elsif from.nil?
		 return "I don't see your From. Check your URL for a correct From input!"
	end
end

# get  "/rick" do
# 	episodes = Rickmorty::Episode.new
# 	episodes.all
# 	api_url = 'https://rickandmortyapi.com/api/character'
# 	response = HTTParty.get( api_url )
#
# 	response["page"].to_json
#
# 	characters = response['results']
# 	character = characters.['name']
#
# 	character
#
#
# end

# get "/deckofcard/randomcard" do
# 	response  = HTTParty.get('https://deckofcardsapi.com/api/deck/new/shuffle/?deck_count=1')
# 	deck_id = response['deck_id']
# 	response = HTTParty.get('https://deckofcardsapi.com/api/deck/' + deck_id + '/draw/?count=1')
# 	response["cards"][0]["value"] + " of " + response["cards"][0]["suit"] + "<img src = '" + response["cards"][0]["image"] + "' />"
# end


def determine_response body
	#normalize and clean the string
		body = body.downcase.strip

		if body == "hi"
			return "This bot is a nice bot!"
		elsif body == "who"
			return "I am MeBot"
		elsif body == "what" || body == "help"
			return "The bot can be used to ask basic things about you"
		elsif body == "where"
			return "You're in Pittsburgh"
		elsif body == "when"
			return "I was made made in Fall 2018."
		elsif body == "why"
			return "I was made for a class project in this class"
		elsif body == "joke" #request for a joke
			array_of_lines = IO.readlines("jokes.txt")
			#display a random joke on the browser
			return "Here you go: " + array_of_lines.sample
		elsif body == "fact" #tell a fact about me
			fun_fact = IO.readlines("facts.txt")
			return fun_fact.sample
		elsif body == "lol" || body == "haha"
			return "Funny right?"
		elsif body == "time"
			time = Time.now
			hour = time.hour
			if hour > 0 && hour < 16
				status = "I am busy either studying or sleeping!"
			else
				status = "Feel free to talk to me!"
			end
			return  status
		elsif body == "random"
			response  = HTTParty.get('https://deckofcardsapi.com/api/deck/new/shuffle/?deck_count=1')
			deck_id = response['deck_id']
			response = HTTParty.get('https://deckofcardsapi.com/api/deck/' + deck_id + '/draw/?count=1')
			response["cards"][0]["value"] + " of " + response["cards"][0]["suit"] + "<img src = '" + response["cards"][0]["image"] + "' />"
		end
end


error 403 do
	"Access Forbidden"
end
