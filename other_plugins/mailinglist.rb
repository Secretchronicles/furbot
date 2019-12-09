# -*- coding: utf-8 -*-

require "open-uri"
require "nokogiri"

class Cinch::MailmanObserver
  include Cinch::Plugin

  timer 60, :method => :check_log

  def check_log
    @currpos ||= nil
    File.open(config[:logfile], "r") do |file|
      if @currpos
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

        while line = file.gets
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
      else
        # First time check -- do not print out everything that's in the file already.
        file.seek(0, IO::SEEK_END)
        @currpos = file.pos
      end
    end
  end

end
