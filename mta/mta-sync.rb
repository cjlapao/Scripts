#!/usr/bin/ruby
# Script to sync the main mta-server and the secondary mta-server in case of failure
#
#
#author: Carlos Lapao
#Ver: 0.2.0.000
#ITTECH24.co.uk
#all rights reserved

require 'open3'
$logdir 					= '/var/log/mta-sync.log'
$_smtp						= '192.168.1.2'
$_smtpuser				= 'it@alara.co.uk'
$_smtppasswd			= 'A1ara45678'
$_email						= 'it@alara.co.uk'

class CheckError
	attr_accessor :error,
								:errorcode,
	 							:lines,
								:sent,
								:received,
								:total

	def initialize(_stdout, _stderror, _stdsuccess)
		@error 			= error
		@errorcode 	= errorcode
		@lines 			= Array.new
		@sent 			= sent
		@recieved 	= received
		@total 			= total

		if _stdsuccess
			@error 			= false
		elsif !_stdsuccess
			@error			= true
		end

		@errorcode 	= _stderror.split(/\n/)
		@stdout 		= _stdout.split(/\n/)
		@sent 			= 0
		@received 	= 0
		@total 			= 0
		collect(@stdout)
	end

	def collect(lines)
		collect = false
		lines.each{|line|
			if !line.nil?
				if line.include? "sending incremental file list"
					collect = true
				end
				if (line.include? "sent ") || (line.include? "total")
					collect = false
				end
				if (line =="\n") && (collect == true)
					collect = false
				end
				if (collect == true) && (!line.include? "sending incremental")
					@lines.push(line)
				end
				if (line.include? "sent") && (line.include? "bytes")
					@sent = line[line.index("sent ")+4..line.index("bytes")-1]
					tline = line[line.index("bytes")+7..line.length]
					if !tline.nil?
						@received = tline[tline.index("received ")+9..tline.index("bytes")-1]
					end
				end
				if line.include? "total"
					@total = line[line.index("is ")+3..line.index("speedup")-1]
				end
			end
		}
	end
end

class GenerateLog
	def initialize(pid,msg)
		output = File.open($logdir,"a")
		date = Time.now
		output.write("#{date} mta-sync[#{pid}]: #{msg}\n")
		output.close
	end
end

class SendEmail
	def initialize(_error,_errorcode)
		begin
			if _error
				_subject = "[Failure] MTA syncronization failed"
				_body = "Alara Systems\n\nThe MTA syncronization failed with the following output\n"
				_errorcode.each{|line|
					_body = "#{_body}#{line.gsub(/[^a-zA-Z0-9]+/, ' ').strip}\n"
				}
			end
			IO.popen("echo '#{_body}' |"+
				"mailx -r 'it@alara.co.uk' -s '#{_subject}' "+
				"-S smtp='#{$_smtp}:25' "+
				"-S smtp-auth=login "+
				"-S smtp-auth-user='#{$_smtpuser}' "+
				"-S smtp-auth-password='#{$_smtppasswd}' "+
				"#{$_email}"){|_io| _io.close}
		rescue StandardError
			puts "\e[0;31mError sending email to administrator, please review the conf file\t\t\t\t[ERROR]\e[0m"
		end
	end
end


class MtaSync
	def initialize
		captured_stdout = '\n'
		captured_stderr = '\n'
		exit_status = Open3.popen3(ENV,"rsync -avz --delete /var/mail/virtual/ root@backupnas:/Backups/mta-rsync") {|stdin, stdout, stderr, wait_thr|
			@pid = wait_thr.pid
			GenerateLog.new(@pid,"Starting syncronization")
			stdin.close
			@captured_stdout = stdout.read
			@captured_stderr = stderr.read
			wait_thr.value
		}
		sync = CheckError.new(@captured_stdout,@captured_stderr,exit_status.success?)
		if !sync.error
			GenerateLog.new(@pid,"syncronization finished sucessfully: sent #{sync.sent} bytes, received #{sync.received} bytes")
		elsif sync.error
			GenerateLog.new(@pid,"There was an error syncronizing the files")
			sync.errorcode.each{|line|
				GenerateLog.new(@pid,line)
			}
			SendEmail.new(sync.error,sync.errorcode)
		end
	end
end
sync = MtaSync.new
