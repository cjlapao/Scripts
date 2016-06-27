#!/usr/bin/ruby
# Script to sync the main mta-server and the secondary mta-server in case of failure
#
#
#author: Carlos Lapao
#Ver: 0.2.0.000
#ITTECH24.co.uk
#all rights reserved

require 'open3'
$logdir 					= '/var/log/settings-sync.log'
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
		}
	end
end

class GenerateLog
	def initialize(pid,msg)
		output = File.open($logdir,"a")
		date = Time.now
		output.write("#{date} bckmta-sync[#{pid}]: #{msg}\n")
		output.close
	end
end

class SendEmail
	def initialize(_error,_errorcode,_syncName)
		begin
			if _error
				_subject = "[Failure] MTA #{_syncName} settings syncronization failed"
				_body = "Alara Systems\n\nThe #{_syncName} settings syncronization failed with the following output\n"
				_errorcode.each{|line|
					_body = "#{_body}#{line.gsub(/[^a-zA-Z0-9]+/, ' ').strip}\n"
				}
			end
			IO.popen("echo '#{_body}' |"+
				"mailx -r 'it@alara.co.uk' -s '#{_subject}' "+
				"-S smtp='#{$_smtp}:587' "+
				"-S smtp-use-starttls "+
				"-S smtp-auth=login "+
				"-S smtp-auth-user='#{$_smtpuser}' "+
				"-S smtp-auth-password='#{$_smtppasswd}' "+
				"-S ssl-verify=ignore "+
				"#{$_email}"){|_io| _io.close}
		rescue StandardError
			puts "\e[0;31mError sending email to administrator, please review the conf file\t\t\t\t[ERROR]\e[0m"
		end
	end
end


class MtaSync
	def initialize
		syncSpamassassin
		syncPostfix
		syncCourier
		syncAmavis
		syncPostgrey
		syncOpendkim
		syncOpendkimConf
		syncOpemdmarc
		syncOpemdmarcConf
		syncPostfixadmin
		syncPostfixadmindb
	end

	def syncSpamassassin
		syncName = 'spamassassin'
		captured_stdout = '\n'
		captured_stderr = '\n'
		exit_status = Open3.popen3(ENV,"rsync -avz --delete /etc/spamassassin/ root@backupnas:/Backups/mta-settings/spamassassin") {|stdin, stdout, stderr, wait_thr|
			@pid = wait_thr.pid
			GenerateLog.new(@pid,"Starting #{syncName} settings syncronization")
			stdin.close
			@captured_stdout = stdout.read
			@captured_stderr = stderr.read
			wait_thr.value
		}
		sync = CheckError.new(@captured_stdout,@captured_stderr,exit_status.success?)
		if !sync.error
			GenerateLog.new(@pid,"syncronization of #{syncName} settings finished sucessfully: sent #{sync.sent} bytes, received #{sync.received} bytes")
		elsif sync.error
			GenerateLog.new(@pid,"There was an error syncronizing #{syncName} settings files")
			sync.errorcode.each{|line|
				GenerateLog.new(@pid,line)
			}
			SendEmail.new(sync.error,sync.errorcode,syncName)
		end
	end

	def syncPostfix
		syncName = 'Postfix'
		captured_stdout = '\n'
		captured_stderr = '\n'
		exit_status = Open3.popen3(ENV,"rsync -avz --delete /etc/postfix/ root@backupnas:/Backups/mta-settings/postfix") {|stdin, stdout, stderr, wait_thr|
			@pid = wait_thr.pid
			GenerateLog.new(@pid,"Starting #{syncName} settings syncronization")
			stdin.close
			@captured_stdout = stdout.read
			@captured_stderr = stderr.read
			wait_thr.value
		}
		sync = CheckError.new(@captured_stdout,@captured_stderr,exit_status.success?)
		if !sync.error
			GenerateLog.new(@pid,"Syncronization of #{syncName} settings finished sucessfully: sent #{sync.sent} bytes, received #{sync.received} bytes")
		elsif sync.error
			GenerateLog.new(@pid,"There was an error syncronizing #{syncName} settings files")
			sync.errorcode.each{|line|
				GenerateLog.new(@pid,line)
			}
			SendEmail.new(sync.error,sync.errorcode,syncName)
		end
	end

	def syncCourier
		syncName = 'Courier'
		captured_stdout = '\n'
		captured_stderr = '\n'
		exit_status = Open3.popen3(ENV,"rsync -avz --delete /etc/courier/ root@backupnas:/Backups/mta-settings/courier") {|stdin, stdout, stderr, wait_thr|
			@pid = wait_thr.pid
			GenerateLog.new(@pid,"Starting #{syncName} settings syncronization")
			stdin.close
			@captured_stdout = stdout.read
			@captured_stderr = stderr.read
			wait_thr.value
		}
		sync = CheckError.new(@captured_stdout,@captured_stderr,exit_status.success?)
		if !sync.error
			GenerateLog.new(@pid,"Syncronization of #{syncName} settings finished sucessfully: sent #{sync.sent} bytes, received #{sync.received} bytes")
		elsif sync.error
			GenerateLog.new(@pid,"There was an error syncronizing #{syncName} settings files")
			sync.errorcode.each{|line|
				GenerateLog.new(@pid,line)
			}
			SendEmail.new(sync.error,sync.errorcode,syncName)
		end
	end

	def syncAmavis
		syncName = 'Amavis'
		captured_stdout = '\n'
		captured_stderr = '\n'
		exit_status = Open3.popen3(ENV,"rsync -avz --delete /etc/amavis/ root@backupnas:/Backups/mta-settings/amavis") {|stdin, stdout, stderr, wait_thr|
			@pid = wait_thr.pid
			GenerateLog.new(@pid,"Starting #{syncName} settings syncronization")
			stdin.close
			@captured_stdout = stdout.read
			@captured_stderr = stderr.read
			wait_thr.value
		}
		sync = CheckError.new(@captured_stdout,@captured_stderr,exit_status.success?)
		if !sync.error
			GenerateLog.new(@pid,"Syncronization of #{syncName} settings finished sucessfully: sent #{sync.sent} bytes, received #{sync.received} bytes")
		elsif sync.error
			GenerateLog.new(@pid,"There was an error syncronizing #{syncName} settings files")
			sync.errorcode.each{|line|
				GenerateLog.new(@pid,line)
			}
			SendEmail.new(sync.error,sync.errorcode,syncName)
		end
	end

	def syncPostgrey
		syncName = 'Postgrey'
		captured_stdout = '\n'
		captured_stderr = '\n'
		exit_status = Open3.popen3(ENV,"rsync -avz --delete /etc/postgrey/ root@backupnas:/Backups/mta-settings/postgey") {|stdin, stdout, stderr, wait_thr|
			@pid = wait_thr.pid
			GenerateLog.new(@pid,"Starting #{syncName} settings syncronization")
			stdin.close
			@captured_stdout = stdout.read
			@captured_stderr = stderr.read
			wait_thr.value
		}
		sync = CheckError.new(@captured_stdout,@captured_stderr,exit_status.success?)
		if !sync.error
			GenerateLog.new(@pid,"Syncronization of #{syncName} settings finished sucessfully: sent #{sync.sent} bytes, received #{sync.received} bytes")
		elsif sync.error
			GenerateLog.new(@pid,"There was an error syncronizing #{syncName} settings files")
			sync.errorcode.each{|line|
				GenerateLog.new(@pid,line)
			}
			SendEmail.new(sync.error,sync.errorcode,syncName)
		end
	end

	def syncOpendkim
		syncName = 'Opendkim'
		captured_stdout = '\n'
		captured_stderr = '\n'
		exit_status = Open3.popen3(ENV,"rsync -avz --delete /etc/opendkim/ root@backupnas:/Backups/mta-settings/opendkim") {|stdin, stdout, stderr, wait_thr|
			@pid = wait_thr.pid
			GenerateLog.new(@pid,"Starting #{syncName} settings syncronization")
			stdin.close
			@captured_stdout = stdout.read
			@captured_stderr = stderr.read
			wait_thr.value
		}
		sync = CheckError.new(@captured_stdout,@captured_stderr,exit_status.success?)
		if !sync.error
			GenerateLog.new(@pid,"Syncronization of #{syncName} settings finished sucessfully: sent #{sync.sent} bytes, received #{sync.received} bytes")
		elsif sync.error
			GenerateLog.new(@pid,"There was an error syncronizing #{syncName} settings files")
			sync.errorcode.each{|line|
				GenerateLog.new(@pid,line)
			}
			SendEmail.new(sync.error,sync.errorcode,syncName)
		end
	end

	def syncOpendkimConf
		syncName = 'Opendkim Config'
		captured_stdout = '\n'
		captured_stderr = '\n'
		exit_status = Open3.popen3(ENV,"rsync -avz --delete /etc/opendkim.conf root@backupnas:/Backups/mta-settings/") {|stdin, stdout, stderr, wait_thr|
			@pid = wait_thr.pid
			GenerateLog.new(@pid,"Starting #{syncName} settings syncronization")
			stdin.close
			@captured_stdout = stdout.read
			@captured_stderr = stderr.read
			wait_thr.value
		}
		sync = CheckError.new(@captured_stdout,@captured_stderr,exit_status.success?)
		if !sync.error
			GenerateLog.new(@pid,"Syncronization of #{syncName} settings finished sucessfully: sent #{sync.sent} bytes, received #{sync.received} bytes")
		elsif sync.error
			GenerateLog.new(@pid,"There was an error syncronizing #{syncName} settings files")
			sync.errorcode.each{|line|
				GenerateLog.new(@pid,line)
			}
			SendEmail.new(sync.error,sync.errorcode,syncName)
		end
	end

	def syncOpemdmarc
		syncName = 'Opendmarc'
		captured_stdout = '\n'
		captured_stderr = '\n'
		exit_status = Open3.popen3(ENV,"rsync -avz --delete /etc/opendmarc/ root@backupnas:/Backups/mta-settings/opendmarc") {|stdin, stdout, stderr, wait_thr|
			@pid = wait_thr.pid
			GenerateLog.new(@pid,"Starting #{syncName} settings syncronization")
			stdin.close
			@captured_stdout = stdout.read
			@captured_stderr = stderr.read
			wait_thr.value
		}
		sync = CheckError.new(@captured_stdout,@captured_stderr,exit_status.success?)
		if !sync.error
			GenerateLog.new(@pid,"Syncronization of #{syncName} settings finished sucessfully: sent #{sync.sent} bytes, received #{sync.received} bytes")
		elsif sync.error
			GenerateLog.new(@pid,"There was an error syncronizing #{syncName} settings files")
			sync.errorcode.each{|line|
				GenerateLog.new(@pid,line)
			}
			SendEmail.new(sync.error,sync.errorcode,syncName)
		end
	end

	def syncOpemdmarcConf
		syncName = 'Opendmarc config'
		captured_stdout = '\n'
		captured_stderr = '\n'
		exit_status = Open3.popen3(ENV,"rsync -avz --delete /etc/opendmarc.conf root@backupnas:/Backups/mta-settings/") {|stdin, stdout, stderr, wait_thr|
			@pid = wait_thr.pid
			GenerateLog.new(@pid,"Starting #{syncName} settings syncronization")
			stdin.close
			@captured_stdout = stdout.read
			@captured_stderr = stderr.read
			wait_thr.value
		}
		sync = CheckError.new(@captured_stdout,@captured_stderr,exit_status.success?)
		if !sync.error
			GenerateLog.new(@pid,"Syncronization of #{syncName} settings finished sucessfully: sent #{sync.sent} bytes, received #{sync.received} bytes")
		elsif sync.error
			GenerateLog.new(@pid,"There was an error syncronizing #{syncName} settings files")
			sync.errorcode.each{|line|
				GenerateLog.new(@pid,line)
			}
			SendEmail.new(sync.error,sync.errorcode,syncName)
		end
	end

	def syncPostfixadmin
		syncName = 'Postfixadmin'
		captured_stdout = '\n'
		captured_stderr = '\n'
		exit_status = Open3.popen3(ENV,"rsync -avz --delete /etc/postfixadmin/ root@backupnas:/Backups/mta-settings/postfixadmin") {|stdin, stdout, stderr, wait_thr|
			@pid = wait_thr.pid
			GenerateLog.new(@pid,"Starting #{syncName} settings syncronization")
			stdin.close
			@captured_stdout = stdout.read
			@captured_stderr = stderr.read
			wait_thr.value
		}
		sync = CheckError.new(@captured_stdout,@captured_stderr,exit_status.success?)
		if !sync.error
			GenerateLog.new(@pid,"Syncronization of #{syncName} settings finished sucessfully: sent #{sync.sent} bytes, received #{sync.received} bytes")
		elsif sync.error
			GenerateLog.new(@pid,"There was an error syncronizing #{syncName} settings files")
			sync.errorcode.each{|line|
				GenerateLog.new(@pid,line)
			}
			SendEmail.new(sync.error,sync.errorcode,syncName)
		end
	end

	def syncPostfixadmindb
		syncName = 'Postfixadmin DB'
		captured_stdout = '\n'
		captured_stderr = '\n'
		exit_status = Open3.popen3(ENV,"rsync -avz --delete /var/lib/mysql/postfixadmin/ root@backupnas:/Backups/mta-settings/postfixadmin-db") {|stdin, stdout, stderr, wait_thr|
			@pid = wait_thr.pid
			GenerateLog.new(@pid,"Starting #{syncName} settings syncronization")
			stdin.close
			@captured_stdout = stdout.read
			@captured_stderr = stderr.read
			wait_thr.value
		}
		sync = CheckError.new(@captured_stdout,@captured_stderr,exit_status.success?)
		if !sync.error
			GenerateLog.new(@pid,"Syncronization of #{syncName} settings finished sucessfully: sent #{sync.sent} bytes, received #{sync.received} bytes")
		elsif sync.error
			GenerateLog.new(@pid,"There was an error syncronizing #{syncName} settings files")
			sync.errorcode.each{|line|
				GenerateLog.new(@pid,line)
			}
			SendEmail.new(sync.error,sync.errorcode,syncName)
		end
	end
end
sync = MtaSync.new
