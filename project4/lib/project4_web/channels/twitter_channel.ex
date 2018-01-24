defmodule Project4Web.TwitterChannel do
    use Phoenix.Channel
    def join("room:server", message, socket) do
        {:ok, socket}
    end

    def handle_in("register", %{"username" => username, "password" => password}, socket) do
        # IO.puts "hi"
        Project4Web.Server.register_user(username, password, socket)
        {:noreply, socket}
    end

    def handle_in("send_tweet", %{"tweet" => tweet, "username" => user}, socket) do
        Project4Web.Server.send_tweet(tweet, user, 0)
        {:noreply, socket}
    end

    def handle_in("retweet", %{"tweet" => tweet, "username" => user}, socket) do
        Project4Web.Server.send_tweet(tweet, user, 1)
        {:noreply, socket}
    end

    def handle_in("mentions", %{"username" => user, "queried" => queried}, socket) do
        IO.puts "inmentions"
        tweets = Project4Web.Server.query_mentions(queried, user)
        IO.inspect tweets
        push socket, "mentions", %{tweets: tweets}
        {:noreply, socket}
    end

    def handle_in("hashtag", %{"username" => user, "hashtag" => hashtag}, socket) do
        tweets = Project4Web.Server.query_hashtag(hashtag, user)
        push socket, "hashtag", %{tweets: tweets}
        {:noreply, socket}
    end
    
    def handle_in("login", %{"username" => user, "password" => password}, socket) do
        # IO.puts "user = #{user} pwd = #{password}"
        ret = Project4Web.Server.login(user, password)
        push socket, "loginsuccessful", %{ret: ret}
        {:noreply, socket}
    end

    def handle_in("get_tweets", %{"username" => user}, socket) do
        tweets = Project4Web.Server.get_tweets(user)
        # IO.inspect tweets
        # IO.puts "gettweets"
        push socket, "return_tweets", %{tweets: tweets}
        {:noreply, socket}
    end

    def handle_in("follow", %{"username" => user, "following_user" => following_user}, socket) do
        Project4Web.Server.follow(user, following_user)
        {:noreply, socket}
    end
end