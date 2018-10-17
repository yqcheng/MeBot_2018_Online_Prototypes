#my Twilio number: (614) 972-1846
require 'twilio-ruby'
require 'rickmorty'
require 'httparty'
require 'giphy'
require 'net/http' #emotion API library
require 'parseconfig'
require 'rest-client'
require 'themoviedb-api'

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

#------------------------------------------------------------------------------
#                         Basic endpoints on web
#------------------------------------------------------------------------------
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
		greet + " new friend! I am Movie Eva, I can give you some movie recommendations if you send me a seflie or text me with keywords I give you! <br/>You have visited " + session["visits"].to_s +
		" times as of " + time.to_s
	else
		greet + " " + session[:first_name] + "I am Movie Eva, I can give you some movie recommendations if you send me a seflie or text me with keywords I give you! <br/>You have visited " + session["visits"].to_s +
		" times as of " + time.to_s
	end
end

#------------------------------------------------------------------------------
#            Use secrete code in URL to get into the sign up page
#------------------------------------------------------------------------------
get "/signup" do
	if params[:code] == code
		erb :signup
	else
		403
	end

end


#------------------------------------------------------------------------------
#                    Sending the first msg after sign up
#------------------------------------------------------------------------------
post "/signup" do
  # we'll add some code here
	# code to check parameters
	client = Twilio::REST::Client.new ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"]

	# Include a message here
	 message = "Hi " + params[:first_name] + ", I am Movie Eva! Are you curious about me? Say hi to me!"

	# this will send a message from any end point
	client.api.account.messages.create(
		from: ENV["TWILIO_FROM"],
		to: params[:number],
		body: message
	)
	# response if eveything is OK on the web page
	"You're signed up. You'll receive a text message in a few minutes from the bot. "

end


#------------------------------------------------------------------------------
#                                 Main:
#               first time greeting + formatting final output
#------------------------------------------------------------------------------
get "/sms/incoming" do
  session["counter"] ||= 1
  imageEmotion = 'empty'
  body = params[:Body] || "Hello!"
	sender = "Qicheng"
  media_content = params[:MediaContentType0] || "none"
  media_url = params[:MediaUrl0] || "none"

  if session["counter"] == 1
     message = "-
Thanks for your first message. I am Movie Eva. I can help you find a movie! Ask me for a movie by texting a genre or your feeling, or send me a selfie!

You can always ask [how] for more help!"
    # media = "https://media.giphy.com/media/13ZHjidRzoi7n2/giphy.gif"
		media = "https://media.giphy.com/media/Hajweqbuiwp20/giphy.gif"
  else


    if media_url == "none"
      message, media = determine_response body

    else
      message, media = call_face_api media_url
    end

  end


	#------------------------------------------------------------------------------
	#                           Twillio package
	#------------------------------------------------------------------------------
	# Build a twilio response object
  twiml = Twilio::TwiML::MessagingResponse.new do |r|
    r.message do |m|

			# add the text of the response
      m.body(message)
      puts message

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


#------------------------------------------------------------------------------
#                            Testing endpoints
#------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------
#                    FACE API Method for sending a picture
#------------------------------------------------------------------------------
# Note: You must use the same region in your REST call as you used to obtain your subscription keys.
#   For example, if you obtained your subscription keys from westcentralus, replace "westus" in the
#   URL below with "westcentralus".

# You must use the same location in your REST call as you used to get your
# subscription keys. For example, if you got your subscription keys from  westus,
# replace "westcentralus" in the URL below with "westus".

def call_face_api media_url

  Tmdb::Api.key("aa73605e3dfbc5266697038b580c3678")

  uri = URI('https://westcentralus.api.cognitive.microsoft.com/face/v1.0/detect')
  uri.query = URI.encode_www_form({
      # Request parameters
      'returnFaceId' => 'true',
      'returnFaceLandmarks' => 'false',
      'returnFaceAttributes' => 'age,gender,headPose,smile,facialHair,glasses,' +
          'emotion,hair,makeup,occlusion,accessories,blur,exposure,noise'
  })

  request = Net::HTTP::Post.new(uri.request_uri)

  # Request headers
  # Replace <Subscription Key> with your valid subscription key.
  request['Ocp-Apim-Subscription-Key'] = '74e4615ad75b40179c0cca590c66615c'
  request['Content-Type'] = 'application/json'

  imageUri = media_url
  request.body = "{\"url\": \"" + imageUri + "\"}"

  response = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
      http.request(request)
  end

  puts "RESPONSE = "
  puts response.body

  json = JSON.parse( response.body )

  emotions = json.first["faceAttributes"]["emotion"]

  searchEmotion = emotions.max_by{|k,v| v}[0]

  if searchEmotion == "happiness"
    response = Tmdb::Genre.movies(12)
    response2 = Tmdb::Genre.movies(10749)
    feeling = "happy"
    puts 'selecting a adventure or romance'
  elsif searchEmotion == "sadness"
    response = Tmdb::Genre.movies(18)
    response2 = Tmdb::Genre.movies(35)
    feeling = "sad"
    puts 'selecting a drama or comedy'
  elsif searchEmotion == "neutral"
    response = Tmdb::Genre.movies(14)
    response2 = Tmdb::Genre.movies(878)
    feeling = "bored"
    puts 'selecting a scifi or fantasy'
  elsif searchEmotion == "anger"
    response = Tmdb::Genre.movies(28)
    response2 = Tmdb::Genre.movies(80)
    feeling = "pissed"
    puts 'selecting a action or crime'
  elsif searchEmotion == "surprise"
    response = Tmdb::Genre.movies(53)
    response2 = Tmdb::Genre.movies(9648)
    feeling = "surprised"
    puts 'selecting a thriller or mystery'
  elsif searchEmotion == "fear"
    response = Tmdb::Genre.movies(10770)
    response2 = Tmdb::Genre.movies(10402)
    feeling = "concerned"
    puts 'selecting a music or tv movie'
  elsif searchEmotion == "disgust"
    response = Tmdb::Genre.movies(16)
    response2 = Tmdb::Genre.movies(10751)
    feeling = "bothered"
    puts 'selecting an animation or family'
  elsif searchEmotion == "contempt"
    response = Tmdb::Genre.movies(99)
    response2 = Tmdb::Genre.movies(36)
    feeling = "to have an attitude"
    puts 'selecting a documentary or history'

  end

  puts "THIS IS THE RANDOM NUMBER --------------"
  puts number_even_odd = rand(2) #a random number for choosing even or odd
  puts number = rand(19)#number of choices in each genre list

  if number_even_odd % 2 == 0
    puts response.results[number]
    title = response['results'][number]["original_title"]
    poster = response['results'][number]["poster_path"]
    overview = response['results'][number]["overview"]
    rating = response['results'][number]["vote_average"]
  else
    puts response2.results[number]
    title = response2['results'][number]["original_title"]
    poster = response2['results'][number]["poster_path"]
    overview = response2['results'][number]["overview"]
    rating = response2['results'][number]["vote_average"]
  end

  media = 'https://image.tmdb.org/t/p/w1280' + poster
  message = '-
You seem ' + feeling + ' today! One option I have for you is ' + title + '.

Rating: ' + rating.to_s + '/10

Overview: ' + overview + '

If you want another option, type [yes].'

  return message, media


end

#------------------------------------------------------------------------------
#                         Method for texting keywords
#------------------------------------------------------------------------------
def determine_response body
	#normalize and clean the string
  body = body.downcase.strip

  # value = call_face_api
  # puts "Highest Emotion is #{value}"

  Tmdb::Api.key("aa73605e3dfbc5266697038b580c3678")

  if body.include?( "adventure") || body.include?("romance") || body.include?("happy") || body.include?("happiness") || body.include?("excited")
    response = Tmdb::Genre.movies(12)
    response2 = Tmdb::Genre.movies(10749)
  elsif body.include?( "drama" )|| body.include?( "comedy" )||body.include?( "sad")|| body.include?( "down")|| body.include?( "not good")|| body.include?( "bad")|| body.include?( "don't feel good")|| body.include?("yes")
    response = Tmdb::Genre.movies(18)
    response2 = Tmdb::Genre.movies(35)
  elsif body.include?( "action" )|| body.include?( "crime" )||body.include?( "anger")|| body.include?( "angry")|| body.include?( "furious")|| body.include?( "outrage")|| body.include?( "mad")|| body.include?( "upset")|| body.include?("sure")
    response = Tmdb::Genre.movies(28)
    response2 = Tmdb::Genre.movies(80)
  elsif body.include?( "fantasy" )|| body.include?( "Science Fiction" )||body.include?( "neutral")|| body.include?( "bored")|| body.include?( "fine")|| body.include?( "nothing")|| body.include?( "okay")|| body.include?( "so so")
    response = Tmdb::Genre.movies(14)
    response2 = Tmdb::Genre.movies(878)
  elsif body.include?( "thriller" )|| body.include?( "mystery" )||body.include?( "surprised")|| body.include?( "suprising")|| body.include?( "unexpected")|| body.include?( "unusual")|| body.include?( "different")
    response = Tmdb::Genre.movies(53)
    response2 = Tmdb::Genre.movies(9648)
  elsif body.include?( "music" )|| body.include?( "tv movie" )||body.include?( "afraid")|| body.include?( "scared")|| body.include?( "movie")|| body.include?( "musical")|| body.include?( "fear")
    response = Tmdb::Genre.movies(10770)
    response2 = Tmdb::Genre.movies(10402)
  elsif body.include?( "animation" )|| body.include?( "family" )||body.include?( "disgusted")|| body.include?( "animate")|| body.include?( "cartoon")
    response = Tmdb::Genre.movies(16)
    response2 = Tmdb::Genre.movies(10751)
  elsif body.include?( "documentary" )|| body.include?( "history" )||body.include?( "contempt")|| body.include?( "historical")|| body.include?( "ancient")
    response = Tmdb::Genre.movies(99)
    response2 = Tmdb::Genre.movies(36)
  elsif body.include?( "no" )|| body.include?( "end" )||body.include?( "stop")|| body.include?( "bye")
    response = "end"
  elsif body.include?( "thanks" )|| body.include?( "thank you" )||body.include?( "appreciate")
    response = "thanks"
  elsif body.include?( "how" )||body.include?( "what")
    response = "help"
  end
    puts "THIS IS THE RANDOM NUMBER --------------"
    puts number_even_odd = rand(2) #a random number for choosing even or odd
    puts number = rand(19)#number of choices in each genre list

    if response.nil?
      message = '-
I hope you found what you want today! You know I am always here if you want some movie recommendations. Just ask me [how] if you are interested!'
      media = "https://media.giphy.com/media/11mcfSXgEAcrKg/giphy.gif"
    elsif response == "end"
      message = '-
I hope you found what you want today! See you later~'
    elsif response == "thanks"
      message = '-
Aww you are welcome! Glad that I could help!'
    elsif response == "help"
      message = '-
Send me a selfie and I will find a movie for your mood today! Or text me with your current feeling like [happy][bored][upset] or genre types like [comedy][action]. '
    else
      if number_even_odd % 2 == 0
        puts response.results[number]
        title = response['results'][number]["original_title"]
        poster = response['results'][number]["poster_path"]
        overview = response['results'][number]["overview"]
        rating = response['results'][number]["vote_average"]
      else
        puts response2.results[number]
        title = response2['results'][number]["original_title"]
        poster = response2['results'][number]["poster_path"]
        overview = response2['results'][number]["overview"]
        rating = response2['results'][number]["vote_average"]
      end

      media = 'https://image.tmdb.org/t/p/w1280' + poster.to_s
      message = '- 
Gotcha! One option I have for you is ' + title + '.

Rating: ' + rating.to_s + '/10

Overview: ' + overview + '

If you want another option, type [yes].'
    end

    return message, media
end


error 403 do
	"Access Forbidden"
end
