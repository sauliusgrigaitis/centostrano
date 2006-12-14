
class Capistrano::Actor

  ##
  # Run a task and ask for input when input_query is seen.
  # Sends the response back to the server.
  #
  # +input_query+ is a regular expression that defaults to /^Password/.
  #
  # Can be used where +run+ would otherwise be used.
  #
  #  run_with_input 'ssh-keygen ...', /^Are you sure you want to overwrite\?/

  def run_with_input(shell_command, input_query=/^Password/)
    handle_command_with_input(:run, shell_command, input_query)
  end

  ##
  # Run a task as root and ask for input when a regular expression is seen.
  # Sends the response back to the server.
  #
  # See also +run_with_input+
  #
  # +input_query+ is a regular expression
  
  def sudo_with_input(shell_command, input_query=/^Password/)
    handle_command_with_input(:sudo, shell_command, input_query)
  end
  
  ##
  # Run a command as root and continuously pipe the results back to the console.
  #
  # Similar to the built-in +stream+, but for privileged users.
  
  def sudo_stream(command)
    sudo(command) do |ch, stream, out|
      puts out if stream == :out
      if stream == :err
        puts "[err : #{ch[:host]}] #{out}"
        break
      end
    end
  end

  private

  ##
  # Does the actual capturing of the input and streaming of the output.
  #
  # local_run_method: run or sudo
  # shell_command: The command to run
  # input_query: A regular expression matching a request for input: /^Please enter your password/
  
  def handle_command_with_input(local_run_method, shell_command, input_query)
    send(local_run_method, shell_command) do |channel, stream, data|
      logger.info data, channel[:host]
      if data =~ input_query
        pass = ::Capistrano::CLI.password_prompt "#{data}:"
        channel.send_data "#{pass}\n"
      end
    end
  end

end
