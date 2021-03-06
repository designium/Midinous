#   Copyright (C) 2019 James "Nornec" Ratliff
#
#   This file is part of Midinous
#
#   Midinous is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   Midinous is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with Midinous.  If not, see <https://www.gnu.org/licenses/>.

module Key_Bindings
	def route_key(event)
		#puts event.keyval
		unless !UI::logic_controls.focus? #Key bindings for the main canvas screen
			case event.keyval
				when 113        # Q
					UI::main_tool_1.signal_emit("keybinding-event") if CC.dragging == false
				when 119        # W
					UI::main_tool_2.signal_emit("keybinding-event") if CC.dragging == false
				when 101, 102   # E or F (colemak)
					UI::main_tool_3.signal_emit("keybinding-event") if CC.dragging == false
				when 114, 112   # R or P (colemak)
					UI::main_tool_4.signal_emit("keybinding-event") if CC.dragging == false
				when 65535      # del
					UI::canvas.signal_emit("delete-selected")
				when 109        # M
				  UI::canvas.signal_emit("mute-toggle")
				when 116        # T
					UI::path_builder.signal_emit("keybinding-event")
				when 93         # ]
					UI::canvas.signal_emit("beat-up")
				when 91         # [
					UI::canvas.signal_emit("beat-dn")				
				when 125        # }
					UI::canvas.signal_emit("beat-note-up")
				when 123        # {
					UI::canvas.signal_emit("beat-note-dn")
				when 60
					UI::canvas.signal_emit("cycle-play-mode-bck")
				when 62
					UI::canvas.signal_emit("cycle-play-mode-fwd")
				when 44 # ,
					UI::canvas.signal_emit('path-rotate-bck')
				when 46 # .
					UI::canvas.signal_emit('path-rotate-fwd')
				when 97
					UI::canvas.signal_emit("set-start")
				when 65367 # end
					UI::canvas.signal_emit("del-path-to")
				when 65360 # home
					UI::canvas.signal_emit("del-path-from")
				when 65365 # page up
					UI::canvas.signal_emit("set-path-mode-h")
				when 65366 # page down
					UI::canvas.signal_emit("set-path-mode-v")
				when 65451, 43 # +
					UI::canvas.signal_emit("note-inc-up")
				when 65453, 95 # -
					UI::canvas.signal_emit("note-inc-dn")
			end
			if (event.keyval == 65462 || event.keyval == 32) && UI::play.sensitive? == true   
				UI::play.signal_emit("keybinding-event")
			elsif (event.keyval == 65461 || event.keyval == 32) && UI::stop.sensitive? == true
				UI::stop.signal_emit("keybinding-event")
			end
		end
		
		unless !UI::prop_mod.focus? #Key bindings for the property modification text entry area
			if event.keyval == 65293 && UI::prop_mod_button.sensitive? == true #Enter key 
				UI::prop_mod.signal_emit("keybinding-event")	
			end
		end
		
	end

end