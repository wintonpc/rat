require 'rspec'
require 'scheduler'

describe 'My behaviour' do
  it 'hello world' do
    s = Scheduler.new
    s.spawn do
      puts 'Hello, World!'
    end
    puts 'done'
  end

  it 'send/receive' do
    s = Scheduler.new
    p = s.spawn do
      s.receive do |msg|
        puts "Got message: #{msg}"
      end
    end
    s.send_msg(p, 'Hello, World!')
    puts 'done'
  end

  it 'telephone' do
    s = Scheduler.new
    chain = 5.downto(1).inject([]) do |chain, i|
      dest = chain.first
      p = s.spawn do
        s.receive do |msg|
          puts "process #{i} got: #{msg}"
          s.send_msg(dest, "#{msg} from #{i}") if dest
        end
      end
      [p, *chain]
    end
    s.send_msg(chain.first, 'gossip')
  end

  it 'ping pong' do
    s = Scheduler.new
    pinger = make_pinger_or_ponger(s, 'ping')
    ponger = make_pinger_or_ponger(s, 'pong')
    s.send_msg(pinger, [ponger, 'hello', 10])
  end

  def make_pinger_or_ponger(s, name)
    s.spawn do
      loop do
        s.receive do |msg|
          sender, content, remaining = msg
          puts "#{name} got #{content}, #{remaining} remain"
          if remaining > 0
            s.send_msg(sender, [s.current_process, content, remaining - 1])
          end
        end
      end
    end
  end

  it 'timer' do
    s = Scheduler.new
    s.spawn do
      s.receive(1000) do |msg|
        if msg == :timeout
          puts 'timed out'
        else
          raise 'oops'
        end
      end
    end
  end
end
