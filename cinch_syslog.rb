# This class ducktypes a Cinch::Logger, i.e. is compatible to it.
# It however does not write to any kind of I/O object, but writes
# to the syslog which needs to be opened before instanciating this
# class.
#
# This class includes code from Cinch's logger.rb. Copyright notice
# is below:
#
# Copyright (c) 2010 Lee Jarvis, Dominik Honnef
# Copyright (c) 2011 Dominik Honnef
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
class CinchSyslogLogger

  LEVELS = [:debug, :log, :info, :warn, :error, :fatal].freeze

  attr_accessor :level

  def initialize
    @level = :debug
  end

  def debug(message)
    log(message, :debug)
  end

  def error(message)
    log(message, :error)
  end

  def fatal(message)
    log(message, :fatal)
  end

  def info(message)
    log(message, :info)
  end

  def warn(message)
    log(message, :warn)
  end

  def incoming(message)
    log(message, :incoming, :log)
  end

  def outgoing(message)
    log(message, :outgoing, :log)
  end

  def exception(e)
    log("#{e.class.name}: #{e.message}: #{e.backtrace.join('|')}", :exception, :error)
  end

  def log(messages, event = :debug, level = event)
    return unless will_log?(level)

    Array(messages).each do |message|
      case event
      when :incoming
        message = "<in> #{message}"
      when :outgoing
        message = "<out> #{message}"
      when :exception
        message = "<ERROR> #{message}"
      end

      message = message.to_s.encode("locale", {:invalid => :replace, :undef => :replace})

      case level
      when :debug, :log
        Syslog.log(Syslog::LOG_DEBUG, "%s", message)
      when :info
        Syslog.log(Syslog::LOG_INFO, "%s", message)
      when :warn
        Syslog.log(Syslog::LOG_WARNING, "%s", message)
      when :error
        Syslog.log(Syslog::LOG_ERR, "%s", message)
      when :fatal
        Syslog.log(Syslog::LOG_CRIT, "%s", message)
      else # Unknown log level
        Syslog.log(Syslog::LOG_NOTICE, "%s", message)
      end
    end
  end

  def will_log?(level)
    LEVELS.index(level) >= LEVELS.index(@level)
  end

end
