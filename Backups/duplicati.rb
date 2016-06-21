#!/usr/bin/ruby
# Script to create backups with duplicati and manage a log and status
#
#
#author: Carlos Lapao
#Ver: 0.0.0.100
#ITTECH24.co.uk
#all rights reserved

require 'yaml'
require 'net/smtp'

$path
$execpath
$execname
$backupcmd

$deleteolderthan
$tempdir
$sourcedir
$backupname

class Sendmail
	def initialize(msg)
  	Net::SMTP.start('mail.alara.co.uk', 25) do |smtp|
      smtp.send_message msg,'it@alara.co.uk','it@alara.co.uk'
		end
  end
end

class Settings
	attr_accessor :destination,
								:path
								:execpath
								:encription
								:encriptionpass
	def initialize
	end
end

#loading setting into memory
if File.exist?("duplicati.properties")
	settings = YAML::load_file("duplicati.properties")
	$execpath = settings["settings"]["execdir"]
	$execname	=settings["settings"]["execname"]
else
	puts "Settings file not set, creating an empty one"
	settings = {"settings" => {"duplicatipath" => "c:/", "execdir" => "c:/"}}
	File.open("duplicati.properties","w"){|io| io.write(settings.to_yaml)}
end

#loading backup tasks into the System
if File.exist?("backups.properties")
	bckps = YAML::load_file("backups.properties")
else
	puts "Settings file not set, creating an empty one"
	bckps = {"backups" => {"" => ""}}
	File.open("backups.properties","w"){|io| io.write(bckps.to_yaml)}
end

if ARGV[0] == "-lst"
	puts "List of available backups"
	bckps["backups"].each{|lst,key| puts "#{lst}\n" }
elsif ARGV[0] == "-bck"
	notfound = true
	bckps["backups"].each{|key,val|
		if ARGV[1].downcase == key.downcase
			notfound = false
			$backupname				= key
			$tempdir 					= bckps["backups"][key]["tempdir"]
			$sourcedir 				= bckps["backups"][key]["sourcedir"]
			$snapshotpolicy 	= bckps["backups"][key]["snapshot"]
			$fullifolder 			= bckps["backups"][key]["fullifolder"]
			$protocol 				= bckps["backups"][key]["destination"]["protocol"]
			if $protocol.downcase == 'webdav://'
				$ftpuser 				= bckps["backups"][key]["destination"]["ftpuser"]
				$ftppass 				= bckps["backups"][key]["destination"]["ftppass"]
			end
			$destinationdir 	= bckps["backups"][key]["destination"]["dir"]
			$deleteolderthan	= bckps["backups"][key]["deleteolderthan"]
			$deleteallbutn		= bckps["backups"][key]["deleteallbutn"]
			break
		end
	}
	if notfound == true
		puts "Didn't find any backups with that name"
	end
else
	puts "no arguments given"
end

class Logline
	attr_accessor :backupname,
								:backuptype,
								:typereason,
								:begintime,
								:endtime,
								:duration,
								:deletedfiles,
								:deletedfolders,
								:modifiedfiles,
								:addedfiles,
								:addedfolders,
								:examinedfiles,
								:openedfiles,
								:sizeofmodified,
								:sizeofadded,
								:sizeofexamined,
								:unprocessed,
								:toolargefiles,
								:fileswitherror,
								:operationname,
								:bytesuploaded,
								:bytesdownloaded,
								:remotecalls,
								:numberoferrors,
								:numberofretries,
								:retryoperation

	def initialize
		@backupname				= backupname
		@backuptype 			= backuptype
		@typereason 			= typereason
		@begintime				= begintime
		@endtime					= endtime
		@duration					= duration
		@deletedfiles			= deletedfiles
		@deletedfolders		= deletedfolders
		@modifiedfiles		= modifiedfiles
		@addedfiles				= addedfiles
		@addedfolders			= addedfolders
		@examinedfiles		= examinedfiles
		@openedfiles			= openedfiles
		@sizeofmodified		= sizeofmodified
		@sizeofadded			= sizeofadded
		@sizeofexamined		= sizeofexamined
		@unprocessed			= unprocessed
		@toolargefiles		= toolargefiles
		@fileswitherror		= fileswitherror
		@operationname		= operationname
		@bytesuploaded		= bytesuploaded
		@bytesdownloaded	= bytesdownloaded
		@remotecalls			= remotecalls
		@numberoferrors		= numberoferrors
		@numberofretries	= numberofretries
		@retryoperation		= retryoperation
	end

	def rawvalue
		fline = ""
		fline = fline+"#{@backupname}"
		fline = fline+"#{@backuptype};"
		fline = fline+"#{@typereason};"
		fline = fline+"#{@begintime};"
		fline = fline+"#{@endtime};"
		fline = fline+"#{@duration};"
		fline = fline+"#{@deletedfiles};"
		fline = fline+"#{@deletedfolders};"
		fline = fline+"#{@modifiedfiles};"
		fline = fline+"#{@addedfiles};"
		fline = fline+"#{@addedfolders};"
		fline = fline+"#{@examinedfiles};"
		fline = fline+"#{@openedfiles};"
		fline = fline+"#{@sizeofmodified};"
		fline = fline+"#{@sizeofadded};"
		fline = fline+"#{@sizeofexamined};"
		fline = fline+"#{@unprocessed};"
		fline = fline+"#{@toolargefiles};"
		fline = fline+"#{@fileswitherror};"
		fline = fline+"#{@operationname};"
		fline = fline+"#{@bytesuploaded};"
		fline = fline+"#{@bytesdownloaded};"
		fline = fline+"#{@remotecalls};"
		fline = fline+"#{@numberoferrors};"
		fline = fline+"#{@numberofretries};"
		fline = fline+"#{@retryoperation}"
		return fline
	end
end

class Log
	@@array = Array.new
	@@fn = ""

	def initialize(_path)
		@@fn = File.open(_path+"/duplicati_backup.log","a+")
		@@fo = @@fn.readlines
		readlog
	end

	def items
		return @@array
	end

	def printline(_index)
		return @@array[_index]
	end

	def readlog
		cindex = 0;
		@@fo.each{|line|
			temp = line[0..line.length-2]
			temp = temp.split(";")
			@@array.push(Logline.new)
			@@array.last.backupname 			= temp[0]
			@@array.last.backuptype 			= temp[1]
			@@array.last.typereason				= temp[2]
			@@array.last.begintime				= temp[3]
			@@array.last.endtime					= temp[4]
			@@array.last.duration					= temp[5]
			@@array.last.deletedfiles			= temp[6]
			@@array.last.deletedfolders		= temp[7]
			@@array.last.modifiedfiles		= temp[8]
			@@array.last.addedfiles				= temp[9]
			@@array.last.addedfolders			= temp[10]
			@@array.last.examinedfiles		= temp[11]
			@@array.last.openedfiles			= temp[12]
			@@array.last.sizeofmodified		= temp[13]
			@@array.last.sizeofadded			= temp[14]
			@@array.last.sizeofexamined		= temp[15]
			@@array.last.unprocessed			= temp[16]
			@@array.last.toolargefiles		= temp[17]
			@@array.last.fileswitherror		= temp[18]
			@@array.last.operationname		= temp[19]
			@@array.last.bytesuploaded		= temp[20]
			@@array.last.bytesdownloaded	= temp[21]
			@@array.last.remotecalls			= temp[22]
			@@array.last.numberoferrors		= temp[23]
			@@array.last.numberofretries	= temp[24]
			@@array.last.retryoperation		= temp[25]
		}
	end

	def addline(_line)
		fline = ""
		if _line.instance_of? Logline
			fline = fline+"#{_line.backupname};"
			fline = fline+"#{_line.backuptype};"
			fline = fline+"#{_line.typereason};"
			fline = fline+"#{_line.begintime};"
			fline = fline+"#{_line.endtime};"
			fline = fline+"#{_line.duration};"
			fline = fline+"#{_line.deletedfiles};"
			fline = fline+"#{_line.deletedfolders};"
			fline = fline+"#{_line.modifiedfiles};"
			fline = fline+"#{_line.addedfiles};"
			fline = fline+"#{_line.addedfolders};"
			fline = fline+"#{_line.examinedfiles};"
			fline = fline+"#{_line.openedfiles};"
			fline = fline+"#{_line.sizeofmodified};"
			fline = fline+"#{_line.sizeofadded};"
			fline = fline+"#{_line.sizeofexamined};"
			fline = fline+"#{_line.unprocessed};"
			fline = fline+"#{_line.toolargefiles};"
			fline = fline+"#{_line.fileswitherror};"
			fline = fline+"#{_line.operationname};"
			fline = fline+"#{_line.bytesuploaded};"
			fline = fline+"#{_line.bytesdownloaded};"
			fline = fline+"#{_line.remotecalls};"
			fline = fline+"#{_line.numberoferrors};"
			fline = fline+"#{_line.numberofretries};"
			fline = fline+"#{_line.retryoperation}\n"
			@@fn.write(fline)
		end
	end

	def save
		@@fn.close
	end
end

class Backups
	def initialize
		@@log = Log.new("c:\\shares\\scripts\\backups")
		ftpuser = ''
		unless $ftpuser.nil?
			ftpuser = "--ftp-username=#{$ftpuser} "+
								"--ftp-password=#{$ftppass} "
		end

		$backupcmd1 = "\"#{$execpath}\\#{$execname} \" "+
				"backup "+
				"--tempdir=#{$tempdir} " +
				"#{ftpuser} "+
				"--passphrase=A1ara45678 "+
				"--aes-encryption-dont-allow-fallback=true "+
				"--snapshot-policy=#{$snapshotpolicy} "+
				"--full-if-older-than=#{$fullifolder} "+
				"#{$sourcedir} "+
				"#{$protocol}#{$destinationdir}"
		puts "1st Step: #{$backupcmd1}"
		$backupcmd2 = "\"#{$execpath}\\#{$execname} \" "+
				"delete-older-than #{$deleteolderthan} "+
				"--tempdir=#{$tempdir} " +
				"--aes-encryption-dont-allow-fallback=true "+
				"--full-if-older-than=#{$fullifolder} "+
				"#{$protocol}#{$destinationdir}"
#		puts "2nd Step: #{$backupcmd2}"
		$backupcmd3 = "\"#{$execpath}\\#{$execname} \" "+
				"delete-all-but-n #{$deleteolderthan} "+
				"--tempdir=#{$tempdir} " +
				"--aes-encryption-dont-allow-fallback=true "+
				"--full-if-older-than=#{$fullifolder} "+
				"#{$protocol}#{$destinationdir}"
#		puts "3rd Step: #{$backupcmd3}"

	end

	def execute
		aline = Logline.new
		#executing the first step of the backup
		IO.popen("#{$backupcmd1}"){|_io|
			@@out = _io.readlines
			_io.close
		}
		aline.backupname			= "None"
		aline.backuptype 			= "0"
		aline.typereason 			= "0"
		aline.begintime				= "0"
		aline.endtime					= "0"
		aline.duration				= "0"
		aline.deletedfiles		= "0"
		aline.deletedfolders	= "0"
		aline.modifiedfiles		= "0"
		aline.addedfiles			= "0"
		aline.addedfolders		= "0"
		aline.examinedfiles		= "0"
		aline.openedfiles			= "0"
		aline.sizeofmodified	= "0"
		aline.sizeofadded			= "0"
		aline.sizeofexamined	= "0"
		aline.unprocessed			= "0"
		aline.toolargefiles		= "0"
		aline.fileswitherror	= "0"
		aline.operationname		= "0"
		aline.bytesuploaded		= "0"
		aline.bytesdownloaded	= "0"
		aline.remotecalls			= "0"
		aline.numberoferrors	= "0"
		aline.numberofretries	= "0"
		aline.retryoperation	= "0"
		if @@out.empty?
			aline.numberoferrors = "1"
			aline.backuptype = "Failure"
			aline.typereason = "Backup failed to execute due to an unknown reason"
		else
		@@out.each_with_index{|line,idx|
			aline.backupname = $backupname
			if line.include?('BackupType')
				aline.backuptype = line[line.index(':') +2..line.length].chomp
			end
			if line.include?('TypeReason')
				aline.typereason = line[line.index(':') +2..line.length].chomp
			end
			if line.include?('BeginTime')
				aline.begintime = line[line.index(':') +2..line.length].chomp
			end
			if line.include?('EndTime')
				aline.endtime = line[line.index(':') +2..line.length].chomp
			end
			if line.include?('Duration')
				aline.duration = line[line.index(':') +2..line.length].chomp
			end
			if line.include?('DeletedFiles')
				aline.deletedfiles = line[line.index(':') +2..line.length].chomp
			end
			if line.include?('DeletedFolders')
				aline.deletedfolders = line[line.index(':') +2..line.length].chomp
			end
			if line.include?('ModifiedFiles')
				aline.modifiedfiles = line[line.index(':') +2..line.length].chomp
			end
			if line.include?('AddedFiles')
				aline.addedfiles = line[line.index(':') +2..line.length].chomp
			end
			if line.include?('AddedFolders')
				aline.addedfolders = line[line.index(':') +2..line.length].chomp
			end
			if line.include?('ExaminedFiles')
				aline.examinedfiles = line[line.index(':') +2..line.length].chomp
			end
			if line.include?('OpenedFiles')
				aline.openedfiles = line[line.index(':') +2..line.length].chomp
			end
			if line.include?('SizeOfModified')
				aline.sizeofmodified = line[line.index(':') +2..line.length].chomp
			end
			if line.include?('SizeOfAdded')
				aline.sizeofadded = line[line.index(':') +2..line.length].chomp
			end
			if line.include?('SizeOfExamined')
				aline.sizeofexamined = line[line.index(':') +2..line.length].chomp
			end
			if line.include?('Unprocessed')
				aline.unprocessed = line[line.index(':') +2..line.length].chomp
			end
			if line.include?('TooLargeFiles')
				aline.toolargefiles = line[line.index(':') +2..line.length].chomp
			end
			if line.include?('FilesWithError')
				aline.fileswitherror = line[line.index(':') +2..line.length].chomp
			end
			if line.include?('OperationName')
				aline.operationname = line[line.index(':') +2..line.length].chomp
			end
			if line.include?('BytesUploaded')
				aline.bytesuploaded = line[line.index(':') +2..line.length].chomp
			end
			if line.include?('BytesDownloaded')
				aline.bytesdownloaded = line[line.index(':') +2..line.length].chomp
			end
			if line.include?('RemoteCalls')
				aline.remotecalls = line[line.index(':') +2..line.length].chomp
			end
			if line.include?('NumberOfErrors')
				aline.numberoferrors = line[line.index(':') +2..line.length].chomp
			end
			if line.include?('Failed to retrieve file listing')
				aline.numberoferrors = 1
			end
			if line.include?('NumberOfRetries')
				aline.numberofretries = line[line.index(':') +2..line.length].chomp
			end
			if line.include?('RetryOperations')
				aline.retryoperation = line[line.index(':') +2..line.length].chomp
			end
			}
		end
		#executing the second step of the backup
		IO.popen("#{$backupcmd2}")
		#executing the second step of the backup
		IO.popen("#{$backupcmd3}")

		@@log.addline(aline)
		if aline.numberoferrors.to_i > 0
			$subject = "[ERROR] [Duplicati Backup] #{$backupname}"
		else
			$subject = "[Duplicati Backup] #{$backupname}"
		end
		report = ""
		@@out.each{|f| report = report+f}

		msgs = <<END_OF_MESSAGE
From: Alara IT System <it@alara.co.uk>
To: it@alara.co.uk
Subject: #{$subject}
Message-Id: <nns@alara.co.uk>

The backup finished with the following output

#{report}

IT Department
END_OF_MESSAGE

		Sendmail.new(msgs)
	end

	def close
		log.save
	end
end

bck = Backups.new

bck.execute
