# -*- coding: utf-8 -*-

require "open-uri"
require "nokogiri"

class Cinch::MailmanObserver
  include Cinch::Plugin

  listen_to :connect, :method => :on_connect
  timer 60, :method => :check_log

  def initialize(*)
    super
    @mailman_log = nil
    @logsize = 0
  end

  def on_connect(*)
    raise(ArgumentError, "No :logfile configured") unless config[:logfile]

    # Do nothing on a subsequent re-connect
    return if @mailman_log

    # Open mailman log file and start reading at its end so that
    # on startup the channel isn't flooded with everything that has
    # ever been written to that log file.
    @mailman_log = File.open(config[:logfile], "r")
    @mailman_log.seek(0, IO::SEEK_END)
    @logsize = File.size(config[:logfile])
  end

  def check_log
    return unless @mailman_log # in case it runs before connect succeeds

    while line = @mailman_log.gets
      if line =~ /HyperKitty archived message <(.*?)> to (https?:\/\/.*)$/
        url = $2

        bot.channels.each{|c| c.send("New mailinglist message: #{url}")}

        html = Nokogiri::HTML(open(url))
        if node = html.at_xpath("html/head/title")
          bot.channels.each{|c| c.send("Subject: #{node.text.strip}")}
        end
      end
    end

    # If the log has been rotated, switch to the new log file.
    # Do not seek to its end, because that would skip log entries
    # that have happened before the switch was detected.
    # If the file on disk as zero size, always assume it has been
    # rotated.
    current_size = File.size(config[:logfile])
    if current_size < @logsize || current_size == 0
      @mailman_log.close
      @mailman_log = File.open(config[:logfile])
      @logsize = current_size
    end

    # Note: There can be the unlikely case that after logrotation and before this
    # timer runs again so much is written to the logfile that it is larger than
    # the rotated logfile. In that case, @mailman_log will not be reopened to
    # the new log file. However, the author deems that case to be unlikely enough
    # to not counter it as doing so would be rather complicated (involving things like
    # inotify). In any case, once that new log is rotated again, it will probably be smaller
    # again.
  end

end
