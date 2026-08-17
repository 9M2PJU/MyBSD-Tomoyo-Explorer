#!/usr/local/bin/ruby -w
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

basepath = nil
if ENV["EXPLORER_BASE"] && File.directory?(ENV["EXPLORER_BASE"])
	basepath = ENV["EXPLORER_BASE"]
else
	%w[tomoyo bsd].each do |path|
		conftry = sprintf('/usr/local/share/%s-explorer/main.conf', path)
		if File.file?(conftry)
			basepath = File.dirname(conftry)
			break
		end
	end
	basepath ||= File.dirname(__FILE__) if File.file?(File.join(File.dirname(__FILE__), 'main.conf'))
end
raise RuntimeError, 'Where is your /usr/local/share/*-explorer/ ?' \
	unless basepath && File.directory?(basepath)

EXPLORER_BASE = basepath

require 'etc'
require 'gtk'
require 'gdk_pixbuf'
require 'Icons'
require 'FileType'
require 'Canvas'
require 'InfoCanvas'
require 'ToolBar'
require 'MenuBar'
require 'Classes_Misc'
require 'Command'
require 'Registry'
require 'ConfParser'
require 'gtk_fix'
require 'Run'
require 'FSCache'
require 'FileSystem'

EXPLORER_VERSION = "1.00-ALPHA"
EXPLORER_RELEASE = "Yamato Nadeshiko"
EXPLORER_RELEASE_DATE = "2002-02-26"

# user, group, home, icons_db, core_icons_db
# ftype_db
ExplorerServer = Struct.new(
	:user,
	:group,
	:home,
	:members,
	:uid,
	:gid,
	:icons_db,
	:core_icons_db,
	:ftype_db,
	:registry_data,
	:popup_style,
	:fs,
	:fonts,
	:fscache,
	:fifo_file,
	:pid_file,
	:all_sessions,
	:exe
)

class Explorer
	ExplorerDirItem = Struct.new(
		:entry,
		:path,
		:ftype,
		:ext,
		:icons,
		:entry_width,
		:truncate,
		:text_height,
		:smode,
		:lsmode,
		:selected,
		:f_stat,
		:f_lstat,
		:x,
		:y
	)
	def initialize(dest)
		@fdb = Reg.ftype_db
		@idb = Reg.icons_db
		@fifo_file = Reg.fifo_file
		@all_sessions = Reg.all_sessions
		@fs = Reg.fs
		@pwd = nil
		@oldpwd = nil
		@pwd_realpath = nil
		@item_pwd = nil
		@is_ufs = true
		@home = Reg.home
		@command = ExplorerCommand.new(self)
		@dir_db = []
		@scandir_list = []
		@dir_db_hash = {}
		@toolbar_stop = false
		@duration = ""
		@main_window = Gtk::Window.new(Gtk::WINDOW_TOPLEVEL)
		@main_window.signal_connect("delete_event") do
			false
		end
		@idle_id = 0
		@main_window.signal_connect("destroy") do
			if @idle_id != 0
				Gtk.idle_remove(@idle_id)
				@idle_id = 0
			end
			unless $EXPLORER_SERVER
				yield if block_given?
				exit(0)
			end
			@all_sessions.delete_if do |ses|
				ses == self
			end
#			@main_window.destroy
			@canvas.canvas_destroy()
#			self.instance_variables.each do |inst|
#				eval("
#					if #{inst}.is_a?(Array) || #{inst}.is_a?(Hash)
#						#{inst}.clear
#					end
#					#{inst} = nil
#				")
#			end
#			ipc_send("-gc")
#			system("/bin/sh -c 'sleep 1 ; explorer -gc' &")
			yield if block_given?
			GC.start()
		end
		@main_window.set_usize(Reg.registry_data['default_width'], Reg.registry_data['default_height'])
		@main_window.set_policy(true, true, true)
		@main_window.realize
		@menubar = ExplorerMenuBar.new(self)
		@toolbar = ExplorerToolBar.new(self)
		@canvas = ExplorerCanvas.new(self)
		@addressbar = ExplorerAddressBar.new(self)
		@info_canvas = ExplorerInfoCanvas.new(self)
		vbox = Gtk::VBox.new(false, 0)
		vbox.pack_start(@menubar, false, true, 0)
		vbox.pack_start(@toolbar, false, true, 0)
		vbox.pack_start(@addressbar, false, true, 0)
		hbox = Gtk::HBox.new(false, 0)
		hbox.pack_start(@info_canvas.main, false, true, 0)
		hbox.pack_start(@canvas.main, true, true, 0)
		vbox.pack_start(hbox, true, true, 0)
		frame = Gtk::Frame.new()
		frame.set_shadow_type(Gtk::SHADOW_IN)
		@status_label = Gtk::Label.new("")
		@status_label.set_alignment(0.0, 0.0)
		@status_label.set_padding(4, 0)
		frame.add(@status_label)
		@main_window.add(vbox)
		@menubar.show_all
		@toolbar.show_all
		@addressbar.show_all
		tb_icon, tb_label = Reg.registry_data['toolbar_show_icon'], Reg.registry_data['toolbar_show_label']
		unless tb_icon && tb_label
			if tb_icon
				@toolbar.main.set_style(Gtk::TOOLBAR_ICONS)
			elsif tb_label
				@toolbar.main.set_style(Gtk::TOOLBAR_TEXT)
			end
		end
		@info_canvas.show
		@canvas.show
		hbox.show
		hbox = Gtk::HBox.new(false, 0)
		hbox.set_spacing(20)
		hbox.pack_start(frame, true, true, 0)
		vbox.pack_start(hbox, false, false, 0)
		@status_label.show
		frame.show
		hbox.show
		vbox.show
		@main_window.show
		unless chdir(dest.nil? ? @home : dest)
			chdir(@home)
		end
		self
	end
	def item_seek(file, entry)
		begin
			file_lstat = File.lstat(file)
			st = ExplorerDirItem.new(
				entry,
				file,
				nil,
				nil,
				[],
				nil,
				nil,
				nil,
				nil,
				file_lstat.mode & 0170000,
				0,
				nil,
				file_lstat,
				nil,
				nil)
		rescue
			return nil
		end
		if st.lsmode == 0120000
			begin
				file_stat = File.stat(file)
				st.smode = file_stat.mode & 0170000
			rescue
				file_stat = file_lstat
				st.smode = st.lsmode
			end
		else
			st.smode = st.lsmode
			file_stat = file_lstat
		end
		st.f_stat = file_stat
		case st.smode
			when 0100000
				st.ftype, st.ext = @fdb.get_ftype(entry)
			when 0040000
				st.ftype = @fdb.get_dtype(file_stat.dev, file_stat.ino)
			when 0010000
				st.ftype = @fdb.named_pipe
			when 0020000
				st.ftype = @fdb.character_device
			when 0060000
				st.ftype = @fdb.block_device
			when 0140000
				st.ftype = @fdb.socket
			else
				st.ftype = @fdb.unknown
		end
		return st
	end
	def chdir(path)
		success = false
		topath = File.expand_path(path, @pwd ? @pwd : ".").gsub(/\/+/, '/')
		begin
			dir = Dir.open(topath)
			success = true
		rescue
			@command.explorer_error($!)
			@toolbar_stop = false
		end
		if success
			if @idle_id != 0
				Gtk.idle_remove(@idle_id)
				@idle_id = 0
				@canvas.handler_unblock()
			end
			@oldpwd = @pwd
			@pwd = topath
			@pwd_realpath = (File.realpath(@pwd) rescue @pwd)
			@canvas.canvas_reinit_pre()
			@is_ufs = @fs.is_ufs?(@pwd_realpath)
			@item_pwd = item_seek(@pwd, ".")
			if @item_pwd && @item_pwd.ftype && @item_pwd.ftype.icons
				@item_pwd.ftype.icons.each do |i|
					@item_pwd.icons << @idb.get(i)
				end
				@item_pwd.icons << @idb.get(2) if @item_pwd.lsmode == 0120000
			end
			@fs.update()
			@dir_db.clear
			@scandir_list.clear
			start_time = Time.now
			dir.each do |ent|
				next if ent == "."
				next if ent == ".."
				@scandir_list << ent
			end
			dir.close
			@idle_id = Gtk.idle_add do
				if @idle_id == 0
					false
				elsif @toolbar_stop
					Gtk.idle_remove(@idle_id)
					@idle_id = 0
					@scandir_list.clear
					@duration = format("%.2f", Time.now - start_time)
					@canvas.canvas_reinit_post()
					false
				elsif (add = @scandir_list.shift)
					if (st = item_seek(@pwd+"/"+add, add))
						@dir_db << st
					end
					true
				else
					Gtk.idle_remove(@idle_id)
					@idle_id = 0
					@scandir_list.clear
					@duration = format("%.2f", Time.now - start_time)
					@canvas.canvas_reinit_post()
					false
				end
			end
		end
		success
	end
	def ipc_send(cmd, pwd = Reg.home)
		begin
			open(Reg.fifo_file, "w") do |fifo|
				fifo.print "#{cmd}\000#{pwd}\n"
			end
		rescue
		end
	end
	attr_reader :pwd, :oldpwd, :pwd_realpath, :item_pwd, :dir_db
	attr_reader :dir_db_hash, :main_window, :menubar, :toolbar
	attr_reader :addressbar, :info_canvas, :canvas, :status_label
	attr_reader :is_ufs, :command, :scandir_list, :duration
	attr_accessor :idle_id, :toolbar_stop
end

def setup_main
	Thread.abort_on_exception = false
	Reg.uid = Etc.getpwuid.uid
	Reg.user = Etc.getpwuid.name
	if Reg.uid == 0 && ENV["USER"] == "toor"
		Reg.user = "toor"
	end
	user_home = (Etc.getpwnam(Reg.user).dir rescue ENV["HOME"] || "/")
	Reg.home = (File.realpath(user_home) rescue user_home)
	Reg.gid = (Etc.getpwnam(Reg.user).gid rescue Process.gid)
	Reg.group = (Etc.getgrgid(Reg.gid).name rescue "users")
	Reg.members = [Reg.group]
	begin
		Etc.group do |group|
			group.mem.each do |name|
				Reg.members.push(group.name) if name == Reg.user
			end
		end
	rescue
	end
	Reg.all_sessions = []
	Reg.members.uniq!
	Reg.exe = (File.realpath($0) rescue $0)
	Reg.fs = FileSystem.new()
	misc_init()
	icons_db_init()
	ftype_db_init()
	Reg.fscache = FSCache.new() if Reg.registry_data["use_fs_cache"]
	font0 = (Gdk::Font.fontset_load(Reg.registry_data["left_info_main_title_font"]) rescue nil)
	font0 ||= (Gdk::Font.font_load("fixed") rescue nil)
	font1 = (Gdk::Font.fontset_load(Reg.registry_data["left_info_preview_title_font"]) rescue nil)
	font1 ||= (Gdk::Font.font_load("fixed") rescue nil)
	Reg.fonts = [font0, font1]

	dummy = Gtk::Window.new()
	dummy.realize
	Reg.popup_style = dummy.style.copy
	Reg.popup_style.set_bg(Gtk::STATE_PRELIGHT,
		Reg.popup_style.bg(Gtk::STATE_SELECTED).red,
		Reg.popup_style.bg(Gtk::STATE_SELECTED).green,
		Reg.popup_style.bg(Gtk::STATE_SELECTED).blue)
	Reg.popup_style.set_fg(Gtk::STATE_PRELIGHT,
		Reg.popup_style.fg(Gtk::STATE_SELECTED).red,
		Reg.popup_style.fg(Gtk::STATE_SELECTED).green,
		Reg.popup_style.fg(Gtk::STATE_SELECTED).blue)
	dummy.destroy
	dummy = nil
end
