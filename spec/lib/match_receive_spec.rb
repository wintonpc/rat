require 'rspec'
require 'match_receive'

describe MatchReceive do
  it 'removes the first matching message from the inbox and evaluates the consequent' do
    msg = [:bar, 42]
    mailbox = [:garbage1, msg, :garbage2]
    result = MatchReceive.instance.receive(mailbox) do |x|
      x.match{[:foo, x]}.then do |x:|
        "got foo with #{x}"
      end
      x.match{[:bar, x]}.then do |x:|
        "got bar with #{x}"
      end
    end
    expect(result).to eql 'got bar with 42'
    expect(mailbox).to eql [:garbage1, :garbage2]
  end

  it 'passes only "requested" bindings' do
    msg = [:bar, 42, 101]
    mailbox = [msg]
    result = MatchReceive.instance.receive(mailbox) do |x|
      x.match{[:bar, x, other]}.then do |x:|
        "got bar with #{x}"
      end
    end
    expect(result).to eql 'got bar with 42'
  end

  it 'passes nil to invalid bindings' do
    msg = [:bar, 42, 101]
    mailbox = [msg]
    result = MatchReceive.instance.receive(mailbox) do |x|
      x.match{[:bar, x, other]}.then do |x:, q:|
        expect(q).to be nil
        "got bar with #{x}"
      end
    end
    expect(result).to eql 'got bar with 42'
  end
end
