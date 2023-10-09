require_relative 'server'

module Generate
  module_function def run
    ::Server.new(*ARGV)
      .tap { Process.kill('USR1', Process.ppid) }
      .start
  end
end

Generate.run if $PROGRAM_NAME == __FILE__
