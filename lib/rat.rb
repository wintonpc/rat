require 'scheduler'

module Rat
  def self.delegate_many(*names)
    names.each do |name|
      class_eval <<EOD
  def #{name}(*args, &block)
    Scheduler.instance.#{name}(*args, &block)
  end
EOD
    end
  end

  delegate_many :spawn, :receive, :match_receive, :send_msg, :current_process, :kill, :spawn_multiple, :exit_process
end
