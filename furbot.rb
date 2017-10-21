#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-

require "cinch"
require "optparse"
require "syslog"
require "fileutils"
require "time"
require_relative "cinch-plugins/plugins/http_server"
require_relative "cinch-plugins/plugins/github_commits"
require_relative "cinch-plugins/plugins/logplus"
require_relative "cinch-plugins/plugins/echo"
require_relative "cinch-plugins/plugins/link_info"
require_relative "cinch-plugins/plugins/vote"
require_relative "cinch-plugins/plugins/tickets"
require_relative "cinch-plugins/plugins/quit"
require_relative "cinch-plugins/plugins/seen"
require_relative "cinch-plugins/plugins/channel_record"
require_relative "other_plugins/shakespeare"
require_relative "cinch_syslog"

DIR = File.dirname(File.expand_path(__FILE__))

#################### Argument handling ####################

$options = {
  :debug => false
}

op = OptionParser.new do |opts|
  opts.banner = "Usage: furbot.rb [OPTIONS]"

  opts.separator ""

  opts.on("-d", "--[no-]debug", "Log verbosely to the standard output."){|bool| $options[:debug] = bool}

  opts.on_tail("-h", "--help"){puts(opts); exit(0)}
end

op.parse!

#################### Cinch specification ####################

cinch = Cinch::Bot.new do
  configure do
    config.server     = "chat.freenode.net"
    config.port       = 6697
    config.ssl.use    = true
    config.ssl.verify = false

    config.channels = ["#secretchronicles"]
    config.nick   = "quintus-furbot"
    config.user   = "quintus-furbot"
    config.realname = "Furball Bot Left"
  end

  # Use this one for testing on a local server instead
  #configure do
  #  config.server     = "localhost"
  #  config.port       = 6667
  #
  #  config.channels = ["#test"]
  #  config.nick   = "furbot"
  #  config.user   = "furbot"
  #  config.realname = "Furball Bot Left"
  #end

  config.plugins.prefix = "!"

  config.plugins.options[Cinch::HttpServer] = {
    :host => "0.0.0.0",
    :port => 46664
  }

  config.plugins.options[Cinch::Seen] = {
    :file => "/tmp/f/other/seenlog.dat",
    :max_age => 60 * 60 * 24 * 365 # 1 year
  }

   config.plugins.options[Cinch::LogPlus] = {
     :logdir  => "/tmp/f/logs/htmllogs",
     :timelogformat => "%H:%M"
  }

   config.plugins.options[Cinch::Vote] = {
     :auth_required => true,
     :voters => %w[brianvanderburg2 Bugsbane DarkAceZ datahead8888 Luiji Quintus_q sauer2 sydneyjd xet7]
   }

  config.plugins.options[Cinch::Tickets] = {
    :url => "https://github.com/Secretchronicles/TSC/issues/%d"
  }

  config.plugins.options[Cinch::Quit] = {
    :op => true
  }

  config.plugins.options[Cinch::ChannelRecord] = {
    :file => "/tmp/f/other/channelrecord.dat"
  }


  config.plugins.plugins = [Cinch::Echo,
                            Cinch::HttpServer,
                            Cinch::GithubCommits,
                            Cinch::LogPlus,
                            Cinch::LinkInfo,
                            Cinch::Tickets,
                            Cinch::Quit,
                            Cinch::Shakespeare,
                            Cinch::Vote,
                            Cinch::Seen,
                            Cinch::ChannelRecord]

  $quitnow = false
  Timer(5) do
    if $quitnow
      bot.loggers.warn $quitnow
      bot.quit($quitnow)
    end
  end

  Timer(60 * 10) do
    bot.nick = "furbot" unless bot.nick == "furbot"
  end

  trap "SIGINT" do
    $quitnow = "Received SIGINT."
  end

  trap "SIGTERM" do
    $quitnow = "Received SIGTERM."
  end

  on :message, /!search (.*)/ do |msg, term|
    msg.channel.send("https://duckduckgo.com/?q=#{CGI.escape(term)}")
  end

  on :message, /!tzconv (.*?) (\w+) to (\w+)$/ do |msg, sourcetimestr, source, target|
    # Time.zone_offset only has a few selected zones.
    # Let’s add some more.
    more_zones = {"CET"  => 60 * 60,     # Central European Time
                  "CEST" => 60 * 60 * 2, # Central European Summer Time
                  "EET"  => 60 * 60 * 2, # Eastern European Time
                  "EEST" => 60 * 60 * 3, # Eastern European Summer Time
                  "WET"  => 0,           # Western European Time
                  "WEST" => 60 * 60,     # Western European Summer Time
                  "WEDT" => 60 * 60,     # Western European Daylight Time
                  "CNST" => 60 * 60 * 8, # Chinese Standard Time
                  "JST"  => 60 * 60 * 9, # Japan Standard Time
                  "ACST" => 60 * 60 * 9 + 30,  # Australian Central Standard Time
                  "ACDT" => 60 * 60 * 10 + 30, # Australian Central Daylight Time
                  "AEST" => 60 * 60 * 10,      # Australian Eastern Standard Time
                  "AEDT" => 60 * 60 * 11,      # Australian Eastern Daylight Time
                  "NZST" => 60 * 60 * 12,      # New Zealand Standard Time
                  "NZDT" => 60 * 60 * 13}      # New Zealand Daylight Time

    sourcetime = Time.parse(sourcetimestr)

    # The above yields a wrong result (local time zone). Force
    # into the correct zone.
    if offset = Time.zone_offset(source) || offset = more_zones[source] # Single = intended
      sourcetime = Time.new(sourcetime.year, sourcetime.month, sourcetime.day,
                            sourcetime.hour, sourcetime.min, sourcetime.sec,
                            offset)
    else
      msg.reply "I don’t know the source timezone #{source}."
      next
    end

    target_offset = Time.zone_offset(target) || more_zones[target]

    unless target_offset
      msg.reply "I don’t know the target timezone #{target}."
      next
    end

    target_time = sourcetime.dup.utc
    target_time += target_offset
    target_time = Time.new(target_time.year, target_time.month, target_time.day,
                           target_time.hour, target_time.min, target_time.sec,
                           target_offset)

    msg.reply "#{sourcetime} in #{target} is #{target_time}"
  end

end

#################### Start action code ####################

# Nice process name
$0 = "furbot"

# Open the syslog
Syslog.open("furbot")
Syslog.log(Syslog::LOG_INFO, "Starting up.")
at_exit do
  Syslog.log(Syslog::LOG_INFO, "Finished, closing syslog.")
  Syslog.close
end

syslogger = CinchSyslogLogger.new
syslogger.level = :info
cinch.loggers.clear unless $options[:debug]
cinch.loggers.push(syslogger)

# Set our file permissions
File.umask 0133 # rw-r--r--

Thread.abort_on_exception = true
Dir.chdir("/")
cinch.start
