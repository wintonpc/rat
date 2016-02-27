class Scheduler

  def initialize
    @runnable = []
    @waiting = []
    @running = nil
  end

  def spawn(&block)
    p = Process.new(&block)
    @waiting.delete(p)
    @runnable.push(p)
    schedule
    p
  end

  def send_msg(process, msg)
    process.mailbox.push(msg)
    schedule
  end

  def receive(&block)
    Fiber.yield
    msg = @running.mailbox.shift
    block.call(msg)
  end

  private

  def schedule
    loop do
      newly_runnable, still_waiting = @waiting.partition{|p| p.mailbox.any?}
      @runnable += newly_runnable
      @waiting = still_waiting
      break if @runnable.none?
      p = @runnable.shift
      @running = p
      p.fiber.resume
      @running = nil
      unless p.exited
        @waiting.push(p)
      end
    end
  end

  class Process
    attr_reader :fiber, :mailbox, :exited

    def initialize(&block)
      @mailbox = []
      @fiber = Fiber.new do
        block.call
        @exited = true
      end
    end
  end
end
