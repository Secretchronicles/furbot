# -*- coding: utf-8 -*-

class Cinch::MailmanObserver
  include Cinch::Plugin

  listen_to :connect, :method => :on_connect
  timer 60, :method => :check_log

  def on_connect(*)
    raise(ArgumentError, "No :logfile configured") unless config[:logfile]

    @mailman_log ||= File.open(config[:logfile], "r")
    @mailman_log.seek(0, IO::SEEK_END)
  end

  def check_log
    return unless defined?(@mailman_log)

    while line = @mailman_log.gets
      if line =~ /HyperKitty archived message <(.*?)> to (https?:\/\/.*)$/
        bot.channels.each{|c| c.send("New mailinglist message: #$2")}
      end
    end

  end

end
