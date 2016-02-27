require 'singleton'
require 'destructure/dmatch'
require 'destructure/sexp_transformer'
require 'binding_of_caller'
require 'sourcify'
require 'abstractivator/proc_ext'

class MatchReceive
  include Singleton

  def receive(mailbox, &block)
    builder = MatcherBuilder.new
    block.call(builder)
    matchers = builder.matchers
    # Dind the earliest message matching the earliest pattern.
    # If a match is found, remove it from the mailbox, invoke
    # the action, and return the result. Otherwise, return :__no_match__
    matchers.each do |matcher|
      mailbox.each_with_index do |msg, i|
        u = DMatch.match(matcher.pat, msg)
        if u
          kws = u.env.map{|(k, v)| [k.name, v]}.to_h
          if matcher.guard.nil? || Proc.loose_call(matcher.guard, [], kws)
            mailbox.delete_at(i)
            return Proc.loose_call(matcher.action, [], kws)
          end
        end
      end
    end
    :__no_match__
  end

  # Ruby "DSL" crap below here

  class MatcherBuilder
    attr_reader :matchers

    def initialize
      @matchers = []
    end

    def match(&pat_block)
      sexp = pat_block.to_sexp(strip_enclosure: true, ignore_nested: true)
      pat = Destructure::SexpTransformer.transform(sexp, binding.of_caller(1)) # must call binding.of_caller in this method. no refactoring.
      matcher = Matcher.new(pat)
      @matchers << matcher
      matcher
    end
  end

  class Matcher
    attr_reader :pat, :guard, :action

    def initialize(pat)
      @pat = pat
    end

    def when(&guard)
      @guard = guard
      self
    end

    def then(&action)
      @action = action
    end
  end
end
