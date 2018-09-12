greetings = ["Hi", "Hello", "What up", "Yo"]
morning = ["Morning", "Good morning"]
afternoon = ["Afternoon", "Good afternoon"]
evening = ["Evening", "Good evening"]

#a secret code for signup
code = "R2D2"

require 'sinatra'
require "sinatra/reloader" if development?


enable :sessions


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
	erb :signup

	code = params[:code]
=begin
	if params[:code] == code
		"You've got the code!"
	else
		403
	end
=end
end


#bug
post "/signup" do
  # we'll add some code here
	if params[:code] == code
		if params[:name]=="" || params[:number]==""
      "Your information is incompelete, please input again!"
    else
      session[:name] = params['first_name']
      session[:number] = params['number']
      session[:visits] = 0
      time = Time.now
      "Welcome! #{session[:name]}! My app dose Blablablabla.
      You will receive a text message in a few minutes from the bot."
    end
  else
    403
  end
end
########################### bug part 7 #######################################



get "/incoming/sms" do
	403
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


	#a method that takes one parameter
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

=begin  ALTERNATIVE READ FILE
			########## open a file ##########
			file = File.open("jokes.txt","r")
			#store every line to an array
			array_of_lines = []
			file.each_line do |line|
				array_of_lines.push line
			end
			``` file.close```
			########## close a file #########
=end

			########## simpler way to read a file ##########
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
		end
	end

		#return value to variable named response
	 response = determine_response params[:Body]

	 	#not necessary to be in the final content, just a practice
	 	#concatenate randomized greetings with response
	 greetings.sample + "! " + response
end






error 403 do
	"Access Forbidden"
end
