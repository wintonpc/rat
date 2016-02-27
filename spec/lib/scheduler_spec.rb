require 'rspec'
require 'rat'

describe Scheduler do
  include Rat

  it 'hello world' do
    spawn do
      puts 'Hello, World!'
    end
    puts 'done'
  end

  it 'send/receive' do
    p = spawn do
      receive_any do |msg|
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
        receive_any do |msg|
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
        receive_any do |msg|
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
      receive_any(1000) do |msg|
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
          receive_any(300) { puts 'fast' }
        end
      end
      slow = spawn do
        loop do
          receive_any(1000) { puts 'slow' }
        end
      end
      spawn do
        receive_any(5000) do
          kill(fast)
          kill(slow)
        end
      end
    end
  end

  it 'exceptions' do
    spawn_multiple do
      fast = spawn do
        loop do
          receive_any(300) { puts 'fast' }
        end
      end
      slow = spawn do
        loop do
          sleep(1000)
          raise 'crash'
        end
      end
      spawn do
        receive_any(2000) do
          kill(fast)
          kill(slow)
        end
      end
    end
  end

  def receive_any(timeout_ms=nil, &block)
    receive(timeout_ms) do |x|
      x.match{z}.then do |z:|
        block.call(z)
      end
    end
  end

  def sleep(ms)
    receive(ms) do |x|
      x.match{:timeout}.then do
        :ok
      end
    end
  end

  it 'match_receive' do
    spawn_multiple do
      p = spawn(linked: true) do
        sleep(20)
        events = []
        master = nil
        loop do
          receive do |x|
            x.match{ p }.when{|p:| p.is_a?(Scheduler::Process)}.then do |p:|
              master = p
            end
            x.match{ [:foo, v] }.then do |v:|
              events << "got foo with #{v}"
            end
            x.match{ [:bar, v] }.then do |v:|
              events << "got bar with #{v}"
            end
            x.match{ [a, b, c] }.then do |a:, b:, c:|
              events << "got #{a} #{b} #{c}"
              expect(events).to eql [ 'got foo with 101',
                                      'got bar with 42',
                                      'got 1 2 3' ]
              send_msg(master, :done)
              exit_process
            end
          end
        end
      end
      spawn do
        send_msg(p, current_process)
        send_msg(p, :garbage)
        send_msg(p, [:bar, 42])
        send_msg(p, [:foo, 101])
        send_msg(p, [1, 2, 3])
        receive do |x|
          x.match{:done}.then do
            exit_process
          end
        end
      end
    end
  end

end
