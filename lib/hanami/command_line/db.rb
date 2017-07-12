module Hanami
  module CommandLine
    # FIXME: this must be a module
    class Db
      include Hanami::Cli::Command
      register "db", subcommand: true

      require "hanami/command_line/db/version"
      require "hanami/command_line/db/create"
    end
  end
end
