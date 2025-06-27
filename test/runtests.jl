import Base.Threads: @spawn
import Aqua
using ZMQ, ZMQPoller, Test

@testset "ZMQPoll" begin

    ctx = Context()
    req1 = Socket(REQ)
    req12 = Socket(REQ)
    rep1 = Socket(REP)
    rep_trigger = Socket(REP)
    req2 = Socket(REQ)
    rep2 = Socket(REP)
    poller = PollItems([req1, rep1, rep2], [ZMQ.POLLIN, ZMQ.POLLIN, ZMQ.POLLIN])

    timeout_ms = 100

    addr = "inproc://s1"
    addr2 = "inproc://s2"
    trigger_addr = "inproc://s3"
    hi = "Hello"
    bye = "World"

    connect(req1, addr)
    connect(req12, addr)
    bind(rep1, addr)
    bind(rep_trigger, trigger_addr)
    bind(rep2, addr2)
    connect(req2, addr2)

    function async_send(addr, trigger_addr, waiting_time)
        hi = "Hello"
        bye = "World"
        req_alt = Socket(REQ)
        connect(req_alt, addr)
        req_trigger = Socket(REQ)
        connect(req_trigger, trigger_addr)
        send(req_trigger, hi)
        sleep(waiting_time)
        send(req_alt, hi)
        close(req_trigger)
        close(req_alt)
    end

    # Polling multiple items
    # case 1: socket received message before poll
    send(req1, hi)
    @test poll(poller, timeout_ms) == 1
    @test poller.revents[2] == ZMQ.POLLIN
    @test recv(rep1, String) == hi
    send(rep1, bye)
    @test poll(poller, timeout_ms) == 1
    recv(req1)

    # case 2: socket received message during poll
    t = @spawn async_send(addr, trigger_addr, timeout_ms * 1.0e-4)
    recv(rep_trigger)
    @test poll(poller, timeout_ms) == 1
    @test poller.revents[2] == ZMQ.POLLIN
    @test poller.revents[1] == 0
    recv(rep1)
    send(rep1, bye)
    @test poll(poller, timeout_ms) == 0
    send(rep_trigger, bye)
    wait(t)

    # case 3: poll times out
    t = @spawn async_send(addr, trigger_addr, timeout_ms * 2.0e-3)
    recv(rep_trigger)
    @test poll(poller, timeout_ms) == 0
    send(rep_trigger, bye)
    wait(t)
    recv(rep1)
    send(rep1, bye)

    # case 4: blocking poll receive before
    send(req1, hi)
    @test poll(poller) == 1
    @test poller.revents[2] == ZMQ.POLLIN
    @test recv(rep1, String) == hi
    send(rep1, bye)
    @test poll(poller) == 1
    recv(req1)

    # case 5: blocking poll receive during
    t = @spawn async_send(addr, trigger_addr, timeout_ms * 1.0e-4)
    recv(rep_trigger)
    @test poll(poller) == 1
    @test poller.revents[2] == ZMQ.POLLIN
    @test poller.revents[1] == 0
    recv(rep1)
    send(rep1, bye)
    @test poll(poller, 100) == 0
    send(rep_trigger, bye)
    wait(t)

    # case 6: multiple sockets receive before call with timeout
    send(req1, hi)
    send(req2, hi)
    @test poll(poller, timeout_ms) == 2
    @test poller.revents[2] == ZMQ.POLLIN
    @test poller.revents[3] == ZMQ.POLLIN
    @test recv(rep1, String) == hi
    @test recv(rep2, String) == hi
    send(rep1, bye)
    send(rep2, bye)
    @test poll(poller, timeout_ms) == 1 # req2 is not in poller
    recv(req1)
    recv(req2)

    # case 7: multiple sockets receive during call with no timeout
    t1 = @spawn async_send(addr, trigger_addr, timeout_ms * 1.0e-4)
    recv(rep_trigger)
    send(rep_trigger, bye)
    t2 = @spawn async_send(addr2, trigger_addr, timeout_ms * 1.0e-4)
    recv(rep_trigger)
    num_events = poll(poller)
    @test 1 <= num_events <= 2 # could return 1 or 2 events
    @test poller.revents[2] == ZMQ.POLLIN || poller.revents[3] == ZMQ.POLLIN
    # if polled messages are not handled, then the poller will keep indicating them
    poller.revents[2] & ZMQ.POLLIN != 0 && recv(rep1)
    poller.revents[3] & ZMQ.POLLIN != 0 && recv(rep2)
    if num_events == 1
        rest = poll(poller)
    else
        rest = poll(poller, timeout_ms)
    end
    @test num_events + rest == 2 # in total there should have been two events
    poller.revents[2] & ZMQ.POLLIN != 0 && recv(rep1)
    poller.revents[3] & ZMQ.POLLIN != 0 && recv(rep2)
    send(rep1, bye)
    send(rep2, bye)
    send(rep_trigger, bye)
    wait(t1)
    wait(t2)

    # case 8: multiple receives on the same socket
    t1 = @spawn async_send(addr, trigger_addr, timeout_ms * 1.0e-4)
    t2 = @spawn async_send(addr, trigger_addr, timeout_ms * 1.0e-4)
    send(req1, hi)
    send(req12, hi)
    send(req2, hi)
    num_sends = 5
    recv(rep_trigger)
    send(rep_trigger, bye)
    recv(rep_trigger)
    send(rep_trigger, bye)
    counter = 0
    while true
        poll(poller)
        if poller.revents[1] & ZMQ.POLLIN != 0
            recv(req1)
        end
        if poller.revents[2] & ZMQ.POLLIN != 0
            recv(rep1)
            send(rep1, bye)
            counter += 1
            counter == num_sends && break
        end
        if poller.revents[3] & ZMQ.POLLIN != 0
            recv(rep2)
            send(rep2, bye)
            counter += 1
            counter == num_sends && break
        end
    end

    close(poller)
    @test_throws StateError poll(poller, 0)

    # case 9 new poller and first time poll without timeout
    t = @spawn begin
        rep3 = Socket(ctx, REP)
        bind(rep3, "inproc://s3")
        poller = PollItems([rep3], [ZMQ.POLLIN])
        @test poll(poller) == 1
        @test recv(rep3, String) == hi
        send(rep3, bye)
        close(poller)
        close(rep3)
    end
    req3 = Socket(ctx, REQ)
    connect(req3, "inproc://s3")
    send(req3, hi)
    @test recv(req3, String) == bye
    wait(t)


    # test that even without poller sockets still functional
    send(req1, hi)
    @test recv(rep1, String) == hi

    close(req1)
    close(req12)
    close(rep1)
    close(req2)
    close(rep2)
    close(rep_trigger)
    close(ctx)
end


@testset "Aqua.jl" begin
    Aqua.test_all(ZMQPoller)
end
