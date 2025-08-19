# Remove ZMQPoller From a Program

ZMQPoller.jl allows to read multiple sockets simultaneously, possibly providing a timeout. 
An alternative to polling sockets through the filewatcher mechanism, which will trigger as soon as a socket receives a message, is to periodically check them for messages.
This is slower than using the filewatcher but is simple enough to implement.

Consider below snippet from the tutorial, which polls three sockets.
```julia
function main_poller()
    ctx = Context()

    receiver = Socket(ctx, PULL)
    connect(receiver, ventilator_addr)

    subscriber = Socket(ctx, SUB)
    connect(subscriber, weather_addr)
    subscribe(subscriber, "")

    killer = Socket(ctx, SUB)
    connect(killer, kill_addr)
    subscribe(killer, "")

    items = PollItems([receiver, subscriber, killer], [ZMQ.POLLIN, ZMQ.POLLIN, ZMQ.POLLIN])

    while true
        poll(items)
        if items.revents[1] & ZMQ.POLLIN != 0
            msg = recv(receiver, String)
            sleep(rand())
            println("Received task $msg")
        end
        if items.revents[2] & ZMQ.POLLIN != 0
            msg = recv(subscriber, String)
            sleep(rand())
            println("Received subscription $msg")
        end
        if items.revents[3] & ZMQ.POLLIN != 0
            println("Received kill signal")
            break
        end
    end
    return
end
```

Instead of using a poller, one could opt for the code below. This will cause more CPU cycles, and higher latency, but avoids the Heisenbugs in the poller implementation.
```julia
function main_poller()
    ctx = Context()

    receiver = Socket(ctx, PULL)
    connect(receiver, ventilator_addr)

    subscriber = Socket(ctx, SUB)
    connect(subscriber, weather_addr)
    subscribe(subscriber, "")

    killer = Socket(ctx, SUB)
    connect(killer, kill_addr)
    subscribe(killer, "")
	
	delay = 1.0e-2 # 10 ms

    while true
		# while loops will read multiple messages 
		# so they're preferable to an if statement
        while receiver.events & ZMQ.POLLIN != 0
            msg = recv(receiver, String)
            sleep(rand())
            println("Received task $msg")
        end
        while subscriber.events & ZMQ.POLLIN != 0
            msg = recv(subscriber, String)
            sleep(rand())
            println("Received subscription $msg")
        end
        while killer.events & ZMQ.POLLIN != 0
            println("Received kill signal")
            break
        end
		sleep(delay)
    end
    return
end
```
