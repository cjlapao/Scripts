#!/usr/bin/ruby
# Script to sync the main mta-server and the secondary mta-server in case of failure
#
#
#author: Carlos Lapao
#Ver: 0.0.0.100
#ITTECH24.co.uk
#all rights reserved
class MtaSync
	def initialize
		IO.popen("rsync -avz --delete /var/mail/virtual/ root@mailbck:/var/mail/virtual"){|_io|
			_out = _io.readlines
			output = File.open("/root/scripts/bckmta-sync.output","a")
			_out.each{|line|
				output.write(line)
			}
			output.write("#{Time.now}########################################################\n\n")
			output.close
			_io.close
		}
	end
end

log = File.open("/var/log/bckmta-sync.log","a")
log.write("#{Time.now} MTA sync started\n")
sync = MtaSync.new
log.write("#{Time.now} MTA sync finished\n")
log.close
