module Capistrano
  # The CLI class encapsulates the behavior of capistrano when it is invoked
  # as a command-line utility. This allows other programs to embed ST and
  # preserve it's command-line semantics.
  class CLI
    
    # Prompt for a password using echo suppression.
    def self.password_prompt(prompt="Password: ")
      sync = STDOUT.sync
      begin
        with_echo do
          STDOUT.sync = true
          print(prompt)
          STDIN.gets.chomp
        end
      ensure
        STDOUT.sync = sync
        puts
      end
    end
    
    def self.prompt(prompt="Password", default=nil)
      sync = STDOUT.sync
      begin
          STDOUT.sync = true
          print("#{prompt}")
          print " [#{default}]" if default
          print ': '
          response = STDIN.gets.chomp
          response == '' ? default : response
      ensure
        STDOUT.sync = sync
        puts
      end
    end
    
  end
end