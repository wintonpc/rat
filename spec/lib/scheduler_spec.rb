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
end
