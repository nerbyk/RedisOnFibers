require_relative 'server'

module Generate
  module_function def run
    ::Server.new(*ARGV).tap do |server|
      Process.kill('USR1', Process.ppid)

      server.start
    end
  end
end

Generate.run if $PROGRAM_NAME == __FILE__
