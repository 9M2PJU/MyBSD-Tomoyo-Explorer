#!/usr/local/bin/ruby -w
#
# Copyright (c) 1999, 2000, 2001, 2002 Ariff Abdullah 
# 	(skywizard@MyBSD.org.my) All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
#	$MyBSD$
#	$FreeBSD$
#

class FileSystem
	def initialize
		@mount_prog = nil
		@df_prog = nil
		@mount_point = []
		@df = {}
		%w[/sbin /usr/sbin /bin /usr/bin].each do |path|
			prog = path+"/mount"
			if test(?f, prog) && test(?x, prog)
				@mount_prog = prog
				break
			end
		end
		%w[/bin /usr/bin].each do |path|
			prog = path+"/df"
			if test(?f, prog) && test(?x, prog)
				@df_prog = prog
				break
			end
		end
		print "Mount program not found\n" if @mount_prog.nil?
		print "DF program not found\n" if @df_prog.nil?
		update()
	end
	def update
		@df.clear
		@mount_point.clear
		if test(?x, @df_prog)
			`#{@df_prog}`.each_line do |l|
				disk = l.split
				@df[disk[0]] = disk[4]
			end
		end
		if test(?x, @mount_prog)
			is_linux = (`/bin/uname`.strip == "Linux" rescue false)
			mount_cmd = is_linux ? "#{@mount_prog}" : "#{@mount_prog} -p"
			`#{mount_cmd} 2>/dev/null`.each_line do |l|
				if is_linux
					if l =~ /^(\S+)\s+on\s+(\S+)\s+type\s+(\S+)/
						dev, mntpt, fs = $1, $2, $3
						begin
							stat = File.stat(mntpt)
							@mount_point.push([dev, mntpt, fs, stat.dev, stat.ino])
						rescue
						end
					end
				else
					ary = l.chomp.split("\t")
					ary.pop
					dev = ary[0]
					ary.shift
					ary[-1] =~ /^([^\s]+)/
					fs = $1
					ary.pop
					mntpt = ary.join("\t")
					begin
						stat = File.stat(mntpt)
						@mount_point.push([dev, mntpt, fs, stat.dev, stat.ino])
					rescue
					end
				end
			end
		end
	end
	def is_ufs?(path)
		ret = true
		real_path = File.realpath(path)
		@mount_point.each do |mnt|
			regex_fs = Regexp.new("^#{mnt[1].sub(/\/$/, '')}/")
			if real_path == mnt[1] || regex_fs =~ real_path
				if mnt[2] =~ /^(ufs|mfs|procfs|ext2fs|cd9660)$/
					ret = true
				else
					ret = false
				end
			end
		end
		ret
	end
	attr_reader :mount_prog, :mount_point, :df
end
