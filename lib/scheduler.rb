class Scheduler

  def initialize
    @runnable = []
    @waiting = []
  end

  def spawn(&block)
    p = Process.new(&block)
    @waiting.delete(p)
    @runnable.push(p)
    schedule
  end

  private

  def schedule
    loop do
      newly_runnable, still_waiting = @waiting.partition{|p| p.mailbox.any?}
      @runnable += newly_runnable
      @waiting = still_waiting
      break if @runnable.none?
      p = @runnable.shift
      p.fiber.resume
    end
  end

  class Process
    attr_reader :fiber, :mailbox

    def initialize(&block)
      @mailbox = []
      @fiber = Fiber.new do
        block.call
      end
    end
  end
end
