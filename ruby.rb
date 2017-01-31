require 'sinatra'
require 'data_mapper'

set :sessions,true

DataMapper.setup(:default,"sqlite:///#{Dir.pwd}/todolist.db")
set :public_folder,File.dirname(__FILE__)+'/static'

class User 
	include DataMapper::Resource
	property :id , Serial
	property :name,String
	property :password,String
	property :friends,String,:length=>1000
end

class Post
	include DataMapper::Resource
	property :id , Serial
	property :message,String,:length=>1000
	property :who_posted, Integer
	property :who_liked, String,:length=>1000
	property :comments,String,:length=>10000
end

DataMapper.finalize
Post.auto_upgrade!
User.auto_upgrade!


get '/'  do
	
	if !session[:current]
		redirect '/signin'
		return;
	end

	user=User.get(session[:current])

	message_list=[]

	friend_string = user.friends
	friend_list=nil
	
	if friend_string
		
		friend_list=friend_string.split(" ")
	
		friend_list.each do |friend|

			friend=friend.to_i

			post_list=Post.all(:who_posted=>friend)

			post_list.each do |post|
				message_list<<post
			end	
		end
	end
	if Post.all(:who_posted=>session[:current])
		
		post_list=Post.all(:who_posted=>session[:current])

			post_list.each do |post|
				message_list<<post
			end	
	end
	
	erb :main,locals:{:user=>user,:message_list=>message_list}

end


get '/signin' do

	erb :signin

end

post '/validate' do

	name=params[:name]
	password=params[:password]

	user=User.all({:name=>name,:password=>password}).first

	if user
		session[:current]=user.id
		redirect '/'
		return
	end

	redirect '/signin'

end


get '/signup' do
	erb :signup
end

post '/register' do

	name=params[:name]
	password=params[:password]

	user=User.all(:name=>name).first

	if user
		redirect '/signup'
		return
	end 

	user=User.new
	user.name=name
	user.password=password
	user.friends=nil
	user.save
	session[:current]=user.id
	redirect '/'

end

post '/logout' do
	session[:current]=nil
	redirect '/'
end

post '/add_message' do

	post=Post.new
	post.message= User.get(session[:current]).name.to_s + "@" + params[:tweet]
	puts "rrr",post.message,"rrr"
	post.who_posted=session[:current]
	post.who_liked=nil
	post.comments=nil
	post.save

	redirect '/'
end

post '/find_friend' do
	# puts ";hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh"

	friend_name=params[:find_friend]
	user = User.all(:name=>friend_name).first
			 # puts user.name,"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

			 

	if user
		message_list=[]
		# puts user.id,";mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm"
		if Post.all(:who_posted=>user.id)
		
			post_list=Post.all(:who_posted=>user.id)

				post_list.each do |post|
					
					message_list<<post
				end	
		end

		erb :find_friends,locals:{:user=>user,:message_list=>message_list}
		
	else
	
		redirect '/'
	end

end


post '/add_friend' do


	friend=params[:friend]

	user=User.get(session[:current])
	friend_user=User.get(friend)
	if friend_user.friends
		friend_user.friends+=" #{user.id.to_s}"
	else
		friend_user.friends=" #{user.id.to_s}"
	end
	if user.friends
		user.friends+=" #{friend.to_s}"
	else
		user.friends=" #{friend.to_s}"
	end
	user.save
	friend_user.save
	redirect '/'
end


post '/like' do

	message_id=params[:lm_id]

	post=Post.get(message_id)

	users=post.who_liked
	flag=0
	if users
		temp_list=users.split(" ")
		
		
		temp_list.each do |user|
			user=user.to_i
			if user == session[:current].to_i
				flag=1
			end
		end
	end
	if flag!=1
		if post.who_liked
			post.who_liked+=" #{session[:current]}"
		else
			post.who_liked=" #{session[:current]}"
		end

		post.save
	end

	redirect '/'

end


post '/display_liker' do

	post=Post.get(params[:post_id].to_i)

	users=post.who_liked

	if users
		temp_list=users.split(" ")
		user_list=[]
		
		temp_list.each do |user|
			user=user.to_i
			user_list<<User.get(user)
		end
		puts "jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj"
		erb :post_likers,locals:{:user_list=>user_list}
		
	else

		redirect '/'
	end
end

post '/add_comment' do

	post = Post.get(params[:id].to_i)

	if post.comments
		post.comments+="#{User.get(session[:current]).name.to_s}"+"@"+params[:comment]+"%"
	else
		post.comments = "#{User.get(session[:current]).name.to_s}"+"@"+params[:comment]+"%"
	end
	post.save

	puts post.comments,"%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"

	redirect '/'
end
