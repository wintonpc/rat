require 'singleton'
require 'match_receive'

class Scheduler
  include Singleton

  def initialize
    @runnable = []
    @waiting = []
    @running = nil
    @timers = []
    @scheduling_disabled = false
  end

  def spawn(linked: false, &block)
    p = Process.new(linked: linked, &block)
    @waiting.delete(p)
    @runnable.push(p)
    schedule
    p
  end

  def send_msg(process, msg)
    process.mailbox.push(msg)
    schedule
  end

  def receive(timeout_ms=nil, &block)
    if timeout_ms
      add_timer(@running, timeout_ms)
    end
    loop do
      result = MatchReceive.instance.receive(@running.mailbox, &block)
      if result == :__no_match__
        wait_me
      else
        return result
      end
    end
  end

  def current_process
    @running
  end

  def spawn_multiple
    @scheduling_disabled = true
    yield
    @scheduling_disabled = false
    schedule
  end

  def kill(process)
    process.kill
  end

  def exit_process
    kill_me
  end

  private

  def schedule
    if @running
      defer_me
    else
      loop do
        break if @scheduling_disabled
        while @timers.any? && @timers.first.instant < Time.now
          t = @timers.shift
          send_msg(t.process, :timeout)
        end
        newly_runnable, still_waiting = @waiting.partition{|p| p.mailbox.any?}
        @runnable += newly_runnable
        @waiting = still_waiting
        @runnable.reject!(&:exited)
        break if @runnable.none?
        p = @runnable.shift
        @running = p
        p.fiber.resume
        @running = nil
      end
      if @timers.any?
      # At least one process is waiting on a timer. Sleep until the earliest one needs to be woken up.
        sleep(@timers.first.instant - Time.now)
        schedule
      end
    end
  end

  def wait_me
    @waiting.push(@running)
    Fiber.yield
  end

  def defer_me
    @runnable.push(@running)
    Fiber.yield
  end

  def kill_me
    Fiber.yield
  end

  class Process
    attr_reader :fiber, :mailbox, :exited

    def initialize(linked: false, &block)
      @mailbox = []
      @fiber = Fiber.new do
        begin
          block.call
        rescue Exception => e
          if linked
            raise e
          else
            puts "EXITED process #{self}: #{e.message}"
          end
        ensure
          @exited = true
        end
      end
    end

    def kill
      @exited = true
    end
  end

  def add_timer(process, ms)
    # insert the timer in the "priority queue"
    raise "Timeout must be greater than zero, but was #{ms}" unless ms > 0
    instant = Time.now + (ms / 1000.0)
    @timers.push(Timer.new(process, instant))
    @timers.sort_by!(&:instant)
  end

  Timer = Struct.new(:process, :instant)
end
