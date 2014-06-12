#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-

require "cinch"
require_relative "cinch_plugins/plugins/github_commits"
require_relative "cinch_plugins/plugins/logplus"
require_relative "cinch_plugins/plugins/echo"

DIR = File.dirname(File.expand_path(__FILE__))

cinch = Cinch::Bot.new do
  configure do
    config.server = "chat.freenode.net"
    config.nick   = "furbot"
    config.user   = "furbot"
    config.realname = "Furball Bot Left"
  end

  config.plugins.prefix = "!"
  
  config.plugins.options[Cinch::HTTPServer] = {
    :host => "0.0.0.0",
    :port => 46664,
    :logfile => "#{DIR}/tmp/httpserver.log"
  }

  config.plugins.plugins = [Cinch::Echo,
                            Cinch::HttpServer,
                            Cinch::GithubCommits]

  trap "SIGINT" do
    bot.log("Cought SIGINT, quitting...", :info)
    bot.quit
  end

  trap "SIGTERM" do
    bot.log("Cought SIGTERM, quitting...", :info)
    bot.quit
  end

  file = File.open("#{DIR}/tmp/bot.log", "a")
  file.sync = true
  loggers.push(Cinch::Logger::FormattedLogger.new(file))
end

cinch.start
