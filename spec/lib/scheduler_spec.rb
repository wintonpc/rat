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
end
