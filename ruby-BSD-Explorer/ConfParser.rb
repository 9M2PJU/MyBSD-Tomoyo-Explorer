#
# Copyright (c) 1999, 2000, 2001 Ariff Abdullah 
# 	(skywizard@MyBSD.org.my). All rights reserved.
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

def icons_db_init
	conf = File.join(Reg.home, ".bsd_explorer", "icons.conf")
	unless test(?f, conf)
		conf = File.join(EXPLORER_BASE, 'icons.conf')
	end
	icons_db_config = {
		'config' => {},
		'core' => [],
		'system' => [],
		'misc' => [],
	}
	parser = {
		'config' => proc {|l|
			if l =~ /^\s*?([^=\s]+?)\s*?=\s*?([^\s]+?)\s*$/
				icons_db_config['config'][$1] = $2
			end
		},
		'core' => proc {|l|
			if l =~ /^\s*?([^\s]+?)\s*$/
				icons_db_config['core'].push($1)
			end
		},
		'system' => proc {|l|
			if l =~ /^\s*?([^\s]+?)\s*$/
				icons_db_config['system'].push($1)
			end
		},
		'misc' => proc {|l|
			if l =~ /^\s*?([^\s]+?)\s*$/
				icons_db_config['misc'].push($1)
			end
		},
	}
	section = ""
	IO.foreach(conf) {|l|
		next if l =~ /^(\s*([;\#].*)?)$/
		if l =~ /^\[\s*([^\[\]]+)\s*\]$/ then
			section = $1.downcase.chomp
			next
		end
		if parser.has_key?(section) then
			parser[section].call(l.sub(/^\s*(.+?)\s*$/, '\1').chomp)
		end
	}

	icons_path = icons_db_config['config']['path']
	if (!icons_path || !File.directory?(icons_path)) && File.directory?(File.join(EXPLORER_BASE, 'icons'))
		icons_path = File.join(EXPLORER_BASE, 'icons')
	end
	path = icons_path+"/"+icons_db_config['config']['theme']
	Reg.core_icons_db = ExplorerIcons.new(
		path,
		icons_db_config['config']['type'],
		nil, nil)
	icons_db_config['core'].each do |i|
		Reg.core_icons_db.add(i)
	end

	Reg.icons_db = ExplorerIcons.new(
		path,
		icons_db_config['config']['type'],
		Reg.registry_data["icon_width"], Reg.registry_data["icon_height"])
	icons_db_config['system'].each do |i|
		Reg.icons_db.add(i)
	end
	Reg.icons_db.raw[99] = nil
	icons_db_config['misc'].each do |i|
		Reg.icons_db.add(i)
	end
end

def ftype_db_init
	Reg.ftype_db = ExplorerFileType.new()
	conf = File.join(Reg.home, ".bsd_explorer", "filetype.conf")
	unless test(?f, conf)
		conf = File.join(EXPLORER_BASE, 'filetype.conf')
	end
	regex_mode = false
	collect = []
	regex = []
	ext = nil
	IO.foreach(conf) {|l|
		next if l =~ /^(\s*([;\#].*)?)$/
		if l =~ /^\[\s*([^\[\]]+)\s*\]$/ then
			sect = $1.upcase
			if sect == "REGEX"
				regex_mode = true
			else
				regex_mode = false
			end
			unless ext == nil
				Reg.ftype_db.add(
					ext.split(','),
					collect[0],
					collect[1] == nil ? nil : collect[1].split(','),
					collect[2] == nil ? nil : collect[2].to_i
				)
			end
			collect.clear 
			ext = regex_mode ? nil : sect
			next
		end
		if regex_mode
			ary = l.chomp.split(',', 3)
			if ary.size == 3 && ary[0].length > 0 && ary[1] =~ /^(true|false)$/i && ary[2].length > 0
				ary[0].upcase!
				if ary[1] =~ /^true$/i
					ary[1] = true
				else
					ary[1] = false
				end
				if ary[2] =~ /^\s*\/?(.+?)\/?(i)?\s*$/ then
					re = $1.dup
					case_sense = $2 == nil ? 0 : 1
					if Reg.ftype_db.has_type?(ary[0])
						ary[2] = Regexp.new(re, case_sense)
						Reg.ftype_db.add_regex(ary)
					else
						print "Warning : ftype doesn't have \"#{ary[0]}\"!!\n"
					end
				end
			end
		else
			if l =~ /^\s*([^\s]+)\s*=\s*?(.+)\s*$/
				key = $1.downcase
				val = $2
				case key
					when "info"
						collect[0] = val
					when "apps"
						collect[1] = val
					when "icon"
						if val =~ /^\d+$/
							collect[2] = val
						end
				end
			end
		end
	}
	unless regex_mode || ext == nil
		Reg.ftype_db.add(
			ext.split(','),
			collect[0],
			collect[1] == nil ? nil : collect[1].split(','),
			collect[2] == nil ? nil : collect[2].to_i
		)
	end
end

def misc_init
	Reg.registry_data = ExplorerRegistry.new()
	conf = File.join(Reg.home, ".bsd_explorer", "main.conf")
	unless test(?f, conf)
		conf = File.join(EXPLORER_BASE, 'main.conf')
	end
	parser = {
		'bookmarks' => proc {|l|
			if l =~ /^([^=]+?)\s*=\s*(.+)$/
				Reg.registry_data["bookmarks"].push([$1, $2])
			end
		},
		'default_apps' => proc {|l|
			Reg.registry_data["default_apps"].push(l)
			Reg.registry_data["default_apps"].compact!
			Reg.registry_data["default_apps"].uniq!
		},
		'general' => proc {|l|
			if l =~ /^([^=]+?)\s*=\s*(.+)$/
				key = $1.downcase
				val = $2
				case val
					when /^(\d+)$/
						val = val.to_i
					when /^(true|yes|y|enable)$/i
						val = true
					when /^(false|no|null|nil|disable|n)$/i
						val = false
				end
				Reg.registry_data[key] = val
			end
		},
	}
	section = nil
	IO.foreach(conf) do |l|
		next if l =~ /^(\s*([;\#].*)?)$/
		if l =~ /^\[\s*([^\[\]]+)\s*\]$/ then
			section = $1.downcase
			next
		end
		if section != nil && parser.has_key?(section) then
			parser[section].call(l.sub(/^\s*(.+?)\s*$/, '\1').chomp)
		end
	end
	ENV["EXPLORER_DEFAULT_XTERM"] = Reg.registry_data["default_xterm"]
end
