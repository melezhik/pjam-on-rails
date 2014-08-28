cwd = File.expand_path(File.join(File.dirname(__FILE__), %w[ ../ ../ ]))
port = 3000
app = :pjam

Eye.config do
    logger "#{cwd}/log/eye.log"
end

Eye.application app do

  working_dir cwd
  stdall "#{cwd}/log/trash.log" # stdout,err logs for processes by default

    group 'dj' do

        workers = (ENV['dj_workers']||'2').to_i
        (1..workers).each do |i|
            process "dj#{i}" do
                pid_file "tmp/pids/delayed_job.#{i}.pid" # pid_path will be expanded with the working_dir
                start_command "./bin/delayed_job start -i #{i}"
                stop_command "./bin/delayed_job stop -i #{i}"
                daemonize false
                stdall "#{cwd}/log/dj.eye.log"
                start_timeout 30.seconds
                stop_timeout 30.seconds
            end
        end

    end

    process :api do
        pid_file "tmp/pids/server.pid"
        start_command "rails server -d -P #{cwd}/tmp/pids/server.pid -p #{port}"
        daemonize false
        stdall "#{cwd}/log/api.eye.log"
        start_timeout 30.seconds
        stop_timeout 30.seconds
    end

end

