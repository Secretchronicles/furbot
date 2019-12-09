# -*- coding: utf-8 -*-

require "open-uri"
require "nokogiri"

class Cinch::MailmanObserver
  include Cinch::Plugin

  listen_to :connect, :method => :on_connect
  timer 60, :method => :check_log

  def on_connect(*)
    raise(ArgumentError, "No :logfile configured") unless config[:logfile]

    # Do nothing on a subsequent re-connect
    return if @logfile
    @logfile = config[:logfile]
    @currpos = 0
  end

  def check_log
    return unless @logfile # in case it runs before connect succeeds

    File.open(@logfile, "r") do |file|
      # If the end position is smaller than the last position,
      # the file has been rotated.
      # This trick fails if immediately after log rotation much
      # is written to the file and immediately before it it
      # had only little content. In that case, reading starts
      # in the middle of the rotated file, skipping the part
      # before @currpos. Should be rare enough to ignore it.
      file.seek(0, IO::SEEK_END)
      @currpos = 0 if file.pos < @currpos
      file.seek(@currpos, IO::SEEK_SET)

      while line = @logfile.gets
        if line =~ /HyperKitty archived message <(.*?)> to (https?:\/\/.*)$/
          url = $2

          bot.channels.each{|c| c.send("New mailinglist message: #{url}")}

          html = Nokogiri::HTML(open(url))
          if node = html.at_xpath("html/head/title")
            bot.channels.each{|c| c.send("Subject: #{node.text.strip}")}
          end
        end
      end

      @currpos = file.pos
    end
  end

end
