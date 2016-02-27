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
end
