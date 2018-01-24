defmodule Project4Web.Server do
    use GenServer
    def start_link() do
        #TODO remove no_users, zipf stuff from state
        GenServer.start_link(__MODULE__, %{registered_users: 0, tweetid: 0}, name: {:global, TwitterServer})
        :global.sync()
        :timer.sleep(:infinity)
    end

    def init(state) do
        #table is of the below format
        # IO.puts "serverinit"
        :ets.new(:users, [:set, :named_table, :public]) #username   password    [followers]   [following]   [offline_msgs] = [{tweetid, msg}]   socket
        # :ets.new(:tweets, [:bag, :named_table, :public]) #tweetid, userid, message
        :ets.new(:hashtag, [:set, :named_table, :public]) #hashtag, [tweetid]
        :ets.new(:mentions, [:set, :named_table, :public]) #username, [tweetid]
        {:ok, state}
    end
    
    def register_user(username, password, socket) do
        GenServer.cast({:global, TwitterServer}, {:registerUser, username, password, socket})
    end

    def handle_cast({:registerUser, username, password, socket}, state) do
        :ets.insert(:users, {username, password, [], [], [], socket})
        # IO.inspect :ets.lookup(:users, username)
        {:noreply, state}
    end

    #type
    #0 - Tweet
    #1 - Retweet
    def send_tweet(message, this_user, type) do
        GenServer.cast({:global, TwitterServer}, {:send_tweet, message, this_user, type})
    end

    def handle_cast({:send_tweet, message, this_user, type}, state) do
        hashtags = Regex.scan(~r/#[a-zA-Z0-9_]+/, message)|> Enum.concat
        mentions = Regex.scan(~r/@[a-zA-Z0-9_]+/, message)|> Enum.concat
        # IO.inspect state
        {:tweetid, tweet_count} = Enum.at(state, 1)
        tweet_count = tweet_count + 1
        if (type == 1) do
            tweetid = "#{this_user}:RT " <> message
        else 
            tweetid = "#{this_user}:" <> message
        end
        if (type == 0) do #normal tweets; 1 - retweets
            if (hashtags != []) do
                Enum.each(hashtags, fn(x) -> #inserts into the table if no entry found for the hashtag else appends and inserts
                    table_val = :ets.lookup(:hashtag, x)
                    if (table_val != []) do
                        [table_val] = table_val
                        tweet_ids = elem(table_val, 1)
                        tweet_ids = tweet_ids ++ ["#{this_user}:" <> message]#[tweetid]
                        :ets.insert(:hashtag, {x, tweet_ids})
                    else
                        :ets.insert(:hashtag, {x, [tweetid]})
                    end
                end)
            end
            if (mentions != []) do
                Enum.each(mentions, fn(x) -> #inserts into the table if no entry found for the mention else appends and inserts
                    table_val = :ets.lookup(:mentions, x)
                    if (table_val != []) do
                        [table_val] = table_val
                        tweet_ids = elem(table_val, 1)
                        tweet_ids = tweet_ids ++ ["#{this_user}:" <> message]#[tweetid]
                        :ets.insert(:mentions, {x, tweet_ids})
                    else
                        :ets.insert(:mentions, {x, ["#{this_user}:" <> message]})#tweetid]})
                    end
                end)
            end
        end
        [user_data] = :ets.lookup(:users, this_user)
        followers = elem(user_data, 2)
        Enum.each(followers, fn(x) ->
            [x_user_data] = :ets.lookup(:users, x)
            offline_msgs = elem(x_user_data, 4)
            # IO.inspect x 
            offline_msgs = offline_msgs ++ [tweetid]
            password = elem(x_user_data, 1)
            this_followers = elem(x_user_data, 2)
            this_following = elem(x_user_data, 3)
            this_socket = elem(x_user_data, 5)
            #put into user table again
            :ets.insert(:users, {x, password, this_followers, this_following, offline_msgs, this_socket})
        end)
        state = Map.put(state, :tweetid, tweet_count)
        {:noreply, state}
    end

    def query_hashtag(hashtag, username) do
        tweets = GenServer.call({:global, TwitterServer}, {:query_hashtags, hashtag, username})
        IO.inspect tweets
        tweets
    end

    def handle_call({:query_hashtags, hashtag, username}, _from, state) do
        tweets = :ets.lookup(:hashtag, hashtag)
        if tweets == [] do
            tweets =["No tweets found!"]
        else
            [{_, tweets}] = tweets
        end
        # Client.print_query(tweets, hashtag, username)
        {:reply, tweets, state}
    end

    def query_mentions(mention, username) do
        GenServer.call({:global, TwitterServer}, {:query_mentions, mention, username})
    end

    def handle_call({:query_mentions, mention, username}, _from, state) do
        mentions = :ets.lookup(:mentions, mention)
        if mentions == [] do
            mentions = ["No tweets found!"]
        else
            [{_, mentions}] = mentions
        end
        IO.inspect mentions
        # Client.print_query(mentions, mention, username)
        {:reply, mentions, state}
    end

    def login(user, password) do
        ret = GenServer.call({:global, TwitterServer}, {:login, user, password})
        ret
    end

    def handle_call({:login, username, password}, _from, state) do
        [user_data] = :ets.lookup(:users, username)
        # IO.puts "login"
        retval = false
        if (password == elem(user_data, 1)) do
            retval = true
        end
        {:reply, retval, state}
    end

    def follow(user, following_user) do
        GenServer.cast({:global, TwitterServer}, {:follow, user, following_user})
    end

    def handle_cast({:follow, user, following_user}, state) do
        [user_data] = :ets.lookup(:users, user)
        #insert as following for current user
        following = elem(user_data, 3)
        if (Enum.member?(following, following_user) == false) do
            IO.puts "following user = #{following_user} user = #{user}"
            following = Enum.concat(following, [following_user])
            # following = following ++ [following_user]
            IO.inspect following
            :ets.insert(:users, {elem(user_data, 0), elem(user_data, 1), elem(user_data, 2), following, elem(user_data, 4), elem(user_data, 5)})
            #insert for the following user as a follower
            [result] = :ets.lookup(:users, following_user)
            followers_list = elem(result, 2)
            # followers_list = followers_list ++ [user]
            followers_list = Enum.concat(followers_list, [user])
            IO.inspect followers_list
            IO.inspect :ets.insert(:users, {elem(result, 0), elem(result, 1), followers_list, elem(result, 3), elem(result, 4), elem(result, 5)})
        end
        # IO.inspect :ets.lookup(:users, user)
        # IO.inspect :ets.lookup(:users, following_user)
        {:noreply, state}
    end

    def get_tweets(username) do
        tweets = GenServer.call({:global, TwitterServer}, {:get_tweets, username})
        tweets
    end

    def handle_call({:get_tweets, username}, _from, state) do
        # IO.inspect username
        [user_data] = :ets.lookup(:users, username)
        # IO.inspect user_data
        offline_tweets = elem(user_data, 4)
        if (offline_tweets == []) do
            offline_tweets = ["No tweets found!"]
        end
        # IO.inspect offline_tweets
        :ets.insert(:users, {elem(user_data, 0), elem(user_data, 1), elem(user_data, 2), elem(user_data, 3), [], elem(user_data, 5)})
        {:reply, offline_tweets, state}
    end
end