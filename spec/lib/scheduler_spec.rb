require 'rspec'
require 'rat'

describe 'My behaviour' do
  include Rat

  it 'hello world' do
    spawn do
      puts 'Hello, World!'
    end
    puts 'done'
  end

  it 'send/receive' do
    p = spawn do
      receive do |msg|
        puts "Got message: #{msg}"
      end
    end
    send_msg(p, 'Hello, World!')
    puts 'done'
  end

  it 'telephone' do
    chain = 5.downto(1).inject([]) do |chain, i|
      dest = chain.first
      p = spawn do
        receive do |msg|
          puts "process #{i} got: #{msg}"
          send_msg(dest, "#{msg} from #{i}") if dest
        end
      end
      [p, *chain]
    end
    send_msg(chain.first, 'gossip')
  end

  it 'ping pong' do
    pinger = make_pinger_or_ponger('ping')
    ponger = make_pinger_or_ponger('pong')
    send_msg(pinger, [ponger, 'hello', 10])
  end

  def make_pinger_or_ponger(name)
    spawn do
      loop do
        receive do |msg|
          sender, content, remaining = msg
          puts "#{name} got #{content}, #{remaining} remain"
          if remaining > 0
            send_msg(sender, [current_process, content, remaining - 1])
          end
        end
      end
    end
  end

  it 'timer' do
    spawn do
      receive(1000) do |msg|
        if msg == :timeout
          puts 'timed out'
        else
          raise 'oops'
        end
      end
    end
  end

  it 'fast and slow' do
    spawn_multiple do
      fast = spawn do
        loop do
          receive(300) { puts 'fast' }
        end
      end
      slow = spawn do
        loop do
          receive(1000) { puts 'slow' }
        end
      end
      spawn do
        receive(5000) do
          kill(fast)
          kill(slow)
        end
      end
    end
  end
end
