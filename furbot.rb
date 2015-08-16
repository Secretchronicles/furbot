#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-

require "cinch"
require "optparse"
require "syslog"
require "etc"
require "fileutils"
require "net/http"
require "net/https"
require "time"
require "enc/trans/single_byte"
require "rack/multipart/parser"
require_relative "cinch-plugins/plugins/http_server"
require_relative "cinch-plugins/plugins/github_commits"
require_relative "cinch-plugins/plugins/logplus"
require_relative "cinch-plugins/plugins/echo"
require_relative "cinch-plugins/plugins/link_info"
require_relative "cinch-plugins/plugins/vote"
require_relative "cinch-plugins/plugins/tickets"
require_relative "cinch-plugins/plugins/quit"
require_relative "cinch-plugins/plugins/seen"
require_relative "other_plugins/shakespeare"

DIR = File.dirname(File.expand_path(__FILE__))
LOGFILE = "/var/log/furbot.log"

if Process.uid != 0
  $stderr.puts "Must be run as root. Use -g and -u options to drop privileges."
  exit 1
end

#################### Argument handling ####################

$options = {
  :daemon => false,
  :pidfile => "/var/run/furbot.pid"
}

op = OptionParser.new do |opts|
  opts.banner = "Usage: furbot.rb [OPTIONS]"

  opts.separator ""

  opts.on("-p", "--pid-file FILE", "Write process ID to FILE on startup"){|path| $options[:pidfile] = path}
  opts.on("-d", "--[no-]daemon", "Daemonize."){|bool| $options[:daemon] = bool}
  opts.on("-u", "--uid NAME", "User to run as."){|uid| $options[:user] = uid}
  opts.on("-g", "--gid NAME", "Group to run as."){|gid| $options[:group] = gid}

  opts.on_tail("-h", "--help"){puts(opts); exit(0)}
end

op.parse!

case ARGV.last
when "stop" then
  unless File.exist?($options[:pidfile])
    $stderr.puts "Not running."
    exit 1
  end

  pid = File.read($options[:pidfile]).to_i

  # Check if such a process exists
  begin
    Process.kill(0, pid)
  rescue Errno::ESRCH
    puts "No process with PID #{pid}, removing stale PIDfile."
    File.delete($options[:pidfile])
    exit 1
  rescue Errno::EPERM
    $stderr.puts "Unable to send signals to process #{pid}!"
    exit 2
  end

  puts "Sending SIGTERM to #{pid}."
  Process.kill("SIGTERM", pid)
  File.delete($options[:pidfile]) # Clean pidfile up so we can start anew

  # If the process does not exit withing 10 seconds, forcibly kill it.
  sleep 10
  begin
    if Process.kill(0, pid) > 0
      # Process still exists, SIGKILL it.
      puts "Process #{pid} still exists, sending SIGKILL."
      Process.kill("SIGKILL", pid)
    end
  rescue Errno::ESRCH
    # Good, process is gone
  end

  # Nothing more to do
  exit
when "start" then
  # Do nothing, continue execution below
else
  $stderr.puts op
  exit
end

#################### Cinch specification ####################

cinch = Cinch::Bot.new do
  configure do
    config.server     = "chat.freenode.net"
    config.port       = 6697
    config.ssl.use    = true
    config.ssl.verify = false

    config.channels = ["#secretchronicles"]
    config.nick   = "furbot"
    config.user   = "furbot"
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
    :port => 46664,
    :logfile => "/other/httpserver.log"
  }

  config.plugins.options[Cinch::Seen] = {
    :file => "/other/seenlog.dat"
  }

   config.plugins.options[Cinch::LogPlus] = {
     :plainlogdir => "/logs/plainlogs",
     :htmllogdir  => "/logs/htmllogs",
     :timelogformat => "%H:%M"
  }

   config.plugins.options[Cinch::Vote] = {
     :auth_required => true,
     :voters => %w[brianvanderburg2 Bugsbane DarkAceZ datahead8888 Luiji Quintus_q sauer2 sydneyjd xet7]
   }

  config.plugins.options[Cinch::Tickets] = {
    :url => "https://github.com/Secretchronicles/SMC/issues/%d"
  }

  config.plugins.options[Cinch::Quit] = {
    :op => true
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
                            Cinch::Seen]

  # Signal handling
  on :connect do
    quitnow = false
    Timer(5) do
      if quitnow
        bot.loggers.warn quitnow
        bot.quit(quitnow)
      end
    end

    trap "SIGINT" do
      quitnow = "Received SIGINT."
    end

    trap "SIGTERM" do
      quitnow = "Received SIGTERM."
    end
  end

  on :message, "!fixnick" do |msg|
    if bot.nick == "furbot"
      msg.reply("Nothing to do.")
    else
      bot.nick = "furbot"
    end
  end

  on :message, /!search (.*)/ do |msg, term|
    msg.channel.send("https://duckduckgo.com/?q=#{CGI.escape(term)}")
  end

  on :message, /!log (\A[a-z|A-Z|\d|.|_|-|#|,]{1,20}\z)$/ do |msg, logsearchtext1|
    # Showing first newest irclog search result
    logresultcounter1 = 0
    logfilelist1 = Dir['/logs/plainlogs/*.log'].sort.reverse
    logfilelist1.each do |logfilename1|
       File.readlines(logfilename1).reverse_each do |filelogline1|
          completelogline1 = "#{logfilename1[-14..-5]} #{filelogline1}"
          if (completelogline1[logsearchtext1])
             logresultcounter1 = logresultcounter1 + 1
             msg.channel.send("#{completelogline1}")
             exit
          end
       end
    end
    if logresultcounter1 == 0 then
       msg.channel.send("Not found.")
    end
    # Cleanup
    logresultcounter1 = nil
    logfilelist1 = nil
    completelogline1 = nil
    filelogline1 = nil
  end

  on :message, /!lognum (\A[a-z|A-Z|\d|.|_|-|#|,]{1,20}\z) (\A[1-9]{4}\z)$/ do |msg, logsearchtext2, logresultnumber2|
    # Showing number x of irclog search result, starting counting from newest first as 1
    logresultcounter2 = 0
    logresultnumber2i = logresultnumber2.to_i
    logfilelist2 = Dir['/logs/plainlogs/*.log'].sort.reverse
    logfilelist2.each do |logfilename2|
       File.readlines(logfilename2).reverse_each do |filelogline2|
          completelogline2 = "#{logfilename2[-14..-5]} #{filelogline2}"
          if (completelogline2[logsearchtext2])
             logresultcounter2 = logresultcounter2 + 1
             if (logresultcounter2 == logresultnumber2i)
                msg.channel.send("#{completelogline2}")
                exit
             end
          end
       end
    end
    if logresultcounter2 == 0 then
       msg.channel.send("Not found.")
    end
    # Cleanup
    logresultcounter2 = nil
    logresultnumber2i = nil
    logfilelist2 = nil
    completelogline2 = nil
    filelogline2 = nil
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

# Open the cinch-specific logfile
logfile = File.open(LOGFILE, "a")
File.chown(0, Etc.getgrnam("adm").gid, LOGFILE) # 0 = root
File.chmod(0640, LOGFILE) # rw-r-----
logfile.sync = true

if $options[:daemon]
  $stdout = $stderr = logfile
  cinch.loggers.clear # Log to $stdout unless daemonized
end

cinch.loggers.push(Cinch::Logger::FormattedLogger.new(logfile))
Syslog.log(Syslog::LOG_INFO, "Detailed log file is at '#{LOGFILE}'.")

# Set our file permissions
File.umask 0133 # rw-r--r--

# Create directories for logging
FileUtils.mkdir_p("#{DIR}/tmp/other")
FileUtils.mkdir_p("#{DIR}/tmp/logs/htmllogs")
FileUtils.mkdir_p("#{DIR}/tmp/logs/plainlogs")

File.chmod(0755, "#{DIR}/tmp/other")
File.chmod(0755, "#{DIR}/tmp/logs")
File.chmod(0755, "#{DIR}/tmp/logs/htmllogs")
File.chmod(0755, "#{DIR}/tmp/logs/plainlogs")

# We need these two later again for privilege dropping
uid = nil
gid = nil
if $options[:user] && $options[:group]
  uid = Etc.getpwnam($options[:user]).uid
  gid = Etc.getgrnam($options[:group]).gid

  File.chown(uid, gid, "#{DIR}/tmp/other")
  File.chown(uid, gid, "#{DIR}/tmp/logs")
  File.chown(uid, gid, "#{DIR}/tmp/logs/htmllogs")
  File.chown(uid, gid, "#{DIR}/tmp/logs/plainlogs")
end

# Daemonize if requested
if $options[:daemon]
  if pid = fork
    Process.detach(pid)
    puts "Forked with PID #{pid}."
    exit
  end

  #### Daemon setup ###

  # Request new session ID
  Process.setsid

  # Close useless streams for cleanup
  STDIN.close
  STDOUT.close
  STDERR.close

  # Bail out if an instance is already running.
  if File.exist?($options[:pidfile])
    Syslog.log(Syslog::LOG_CRIT, "PID file #{$options[:pidfile]} already exists. Exiting.")
    exit 1
  end

  # Write PID into PIDfile. Note we do not change PIDfile ownership to
  # prevent a PIDfile injection attack that wants to fool the process
  # manager. The PIDfile is unwritable for us after privilege dropping.
  File.open($options[:pidfile], "w"){|f| f.write($$)}

  Syslog.log(Syslog::LOG_INFO, "Wrote PID #{$$} to PIDfile '#{$options[:pidfile]}'.")
else
  # Never write a PIDfile if not a daemon
  $options.delete :pidfile

  # Crash completely if not daemon and a thread crashes
  Thread.abort_on_exception = true
end

# Ensure there’s a NULL device in the chroot
unless File.directory?("#{DIR}/tmp/dev")
  Dir.mkdir("#{DIR}/tmp/dev")
  File.chmod(0755, "#{DIR}/tmp/dev")
end
system("mknod -m 666 '#{DIR}/tmp/dev/null' c 1 3") unless File.exist?("#{DIR}/tmp/dev/null")

# Chroot so no external access anymore.
Dir.chroot("#{DIR}/tmp")
Dir.chdir("/")

# Drop privileges
Process::Sys.setgid(gid) if $options[:group]
Process::Sys.setuid(uid) if $options[:user]

# Ensure we have permanently lost privileges
if $options[:user]
  begin
    Process::Sys.setuid(0)
  rescue Errno::EPERM
    Syslog.log(Syslog::LOG_INFO, "Successfully dropped privileges.")
  else
    Syslog.log(Syslog::LOG_CRIT, "Regained root privileges! Exiting!")
    raise "Regained root privileges!"
  end
end

cinch.start
