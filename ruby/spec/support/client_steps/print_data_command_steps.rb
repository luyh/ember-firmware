require 'fileutils'

module Smith
  PrintDataCommandSteps = RSpec::EM.async_steps do

    def assert_print_data_command_handled_when_print_data_command_received_when_file_not_already_loaded_when_print_data_load_succeeds(&callback)
      d1 = add_command_pipe_expectation do |command|
        expect(command).to eq(CMD_SHOW_PRINT_DATA_DOWNLOADING)
      end

      d2 = add_command_pipe_expectation do |command|
        expect(command).to eq(CMD_START_PRINT_DATA_LOAD)
      end

      d3 = add_command_pipe_expectation do |command|
        expect(command).to eq(CMD_PROCESS_PRINT_DATA)
        expect(File.read(File.join(print_data_dir, test_print_file))).to eq("test print file contents\n")
        expect(print_settings_file_contents).to eq(print_settings)
      end

      d4 = add_http_request_expectation acknowledge_endpoint do |request_params|
        expect(request_params[:state]).to eq(Client::Command::RECEIVED_ACK)
        expect(request_params[:command]).to eq(Client::PRINT_DATA_COMMAND)
        expect(request_params[:command_token]).to eq('123456')
      end

      d5 = add_http_request_expectation acknowledge_endpoint do |request_params|
        expect(request_params[:state]).to eq(Client::Command::COMPLETED_ACK)
        expect(request_params[:command]).to eq(Client::PRINT_DATA_COMMAND)
        expect(request_params[:command_token]).to eq('123456')
      end

      when_succeed(d1, d2, d3, d4, d5) { callback.call }

      dummy_server.post_command(
        command: Client::PRINT_DATA_COMMAND,
        command_token: '123456',
        file_url: dummy_server.test_print_file_url,
        settings: print_settings
      )
    end

    def assert_print_data_command_handled_when_print_data_command_received_when_file_already_loaded_when_load_settings_succeeds(&callback)
      d1 = add_command_pipe_expectation do |command|
        expect(command).to eq(CMD_START_PRINT_DATA_LOAD)
      end
      
      d2 = add_command_pipe_expectation do |command|
        expect(command).to eq(CMD_APPLY_PRINT_SETTINGS)
        expect(print_settings_file_contents).to eq(print_settings)
      end
      
      d3 = add_command_pipe_expectation do |command|
        expect(command).to eq(CMD_SHOW_PRINT_DATA_LOADED)
      end

      d4 = add_http_request_expectation acknowledge_endpoint do |request_params|
        expect(request_params[:state]).to eq(Client::Command::RECEIVED_ACK)
        expect(request_params[:command]).to eq(Client::PRINT_DATA_COMMAND)
        expect(request_params[:command_token]).to eq('123456')
      end

      d5 = add_http_request_expectation acknowledge_endpoint do |request_params|
        expect(request_params[:state]).to eq(Client::Command::COMPLETED_ACK)
        expect(request_params[:command]).to eq(Client::PRINT_DATA_COMMAND)
        expect(request_params[:command_token]).to eq('123456')
      end

      when_succeed(d1, d2, d3, d4, d5) { callback.call }

      dummy_server.post_command(
        command: Client::PRINT_DATA_COMMAND,
        command_token: '123456',
        file_url: "#{dummy_server.url}/#{print_file_name}",
        settings: print_settings
      )
    end

    def assert_print_data_command_handled_when_print_data_command_received_when_file_already_loaded_when_printer_not_in_valid_state(&callback)
      d1 = add_http_request_expectation acknowledge_endpoint do |request_params|
        expect(request_params[:state]).to eq(Client::Command::RECEIVED_ACK)
        expect(request_params[:command]).to eq(Client::PRINT_DATA_COMMAND)
        expect(request_params[:command_token]).to eq('123456')
      end

      d2 = add_http_request_expectation acknowledge_endpoint do |request_params|
        expect(request_params[:state]).to eq(Client::Command::FAILED_ACK)
        expect(request_params[:command]).to eq(Client::PRINT_DATA_COMMAND)
        expect(request_params[:command_token]).to eq('123456')
        expect(request_params[:message]).to match(/#{Printer::InvalidState}/)
      end
     
      when_succeed(d1, d2) { callback.call }

      dummy_server.post_command(
        command: Client::PRINT_DATA_COMMAND,
        command_token: '123456',
        file_url: "#{dummy_server.url}/#{print_file_name}",
        settings: print_settings
      )
    end

    def assert_print_data_dir_purged_before_print_file_download(&callback)
      expect(File.exists?(stray_print_file)).to eq(false)
      callback.call
    end

    def touch_stray_print_file(&callback)
      # Create old print file that needs to be deleted before downloading the new file
      # A stray file might exist as a result of an error during print data processing
      FileUtils.touch(stray_print_file)
      callback.call
    end

    def assert_error_acknowledgement_sent_when_print_data_command_received_when_printer_not_in_valid_state_after_download(&callback)
      d1 = add_command_pipe_expectation do |command|
        expect(command).to eq(CMD_SHOW_PRINT_DATA_DOWNLOADING)
      end

      d2 = add_command_pipe_expectation do |command|
        expect(command).to eq(CMD_START_PRINT_DATA_LOAD)
      end

      d3 = add_http_request_expectation acknowledge_endpoint do |request_params|
        expect(request_params[:state]).to eq(Client::Command::RECEIVED_ACK)
        expect(request_params[:command]).to eq(Client::PRINT_DATA_COMMAND)
        expect(request_params[:command_token]).to eq('123456')
      end

      d4 = add_http_request_expectation acknowledge_endpoint do |request_params|
        expect(request_params[:state]).to eq(Client::Command::FAILED_ACK)
        expect(request_params[:command]).to eq(Client::PRINT_DATA_COMMAND)
        expect(request_params[:command_token]).to eq('123456')
      end
     
      when_succeed(d1, d2, d3, d4) { callback.call }

      dummy_server.post_command(
        command: Client::PRINT_DATA_COMMAND,
        command_token: '123456',
        file_url: dummy_server.test_print_file_url,
        settings: print_settings
      )
    end

    def assert_error_acknowledgement_sent_when_print_data_command_received(&callback)

      d1 = add_http_request_expectation acknowledge_endpoint do |request_params|
        expect(request_params[:state]).to eq(Client::Command::RECEIVED_ACK)
        expect(request_params[:command]).to eq(Client::PRINT_DATA_COMMAND)
        expect(request_params[:command_token]).to eq('123456')
      end

      d2 = add_http_request_expectation acknowledge_endpoint do |request_params|
        expect(request_params[:state]).to eq(Client::Command::FAILED_ACK)
        expect(request_params[:command]).to eq(Client::PRINT_DATA_COMMAND)
        expect(request_params[:command_token]).to eq('123456')
      end
     
      when_succeed(d1, d2) { callback.call }

      dummy_server.post_command(
        command: Client::PRINT_DATA_COMMAND,
        command_token: '123456',
        file_url: dummy_server.test_print_file_url,
        settings: print_settings
      )
    end

    def assert_print_file_not_downloaded(&callback)
      expect(File.exist?(File.join(print_data_dir, test_print_file))).to be(false)
      callback.call
    end

    def assert_error_acknowledgement_sent_when_print_data_command_received_when_download_fails(&callback)

      d1 = add_http_request_expectation acknowledge_endpoint do |request_params|
        expect(request_params[:state]).to eq(Client::Command::RECEIVED_ACK)
        expect(request_params[:command]).to eq(Client::PRINT_DATA_COMMAND)
        expect(request_params[:command_token]).to eq('123456')
      end

      d2 = add_http_request_expectation acknowledge_endpoint do |request_params|
        expect(request_params[:state]).to eq(Client::Command::FAILED_ACK)
        expect(request_params[:command]).to eq(Client::PRINT_DATA_COMMAND)
        expect(request_params[:command_token]).to eq('123456')
      end

      d3 = add_command_pipe_expectation do |command|
        expect(command).to eq(CMD_SHOW_PRINT_DATA_DOWNLOADING)
      end

      d4 = add_command_pipe_expectation do |command|
        expect(command).to eq(CMD_SHOW_PRINT_DOWNLOAD_FAILED)
      end

      when_succeed(d1, d2, d3, d4) { callback.call }

      dummy_server.post_command(
        command: Client::PRINT_DATA_COMMAND,
        command_token: '123456',
        file_url: dummy_server.invalid_url,
        settings: print_settings 
      )
    end

  end
end
