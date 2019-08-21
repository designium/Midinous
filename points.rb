class Point_Logic
	include Logic_Controls
	
	def initialize
		@prop_names = ["Note","Velocity","Duration (%)","Channel","X-coordinate","Y-coordinate","Color","Path Mode","Signal Start"]
		@curr_prop = nil
	end
	
	def add_point(r_origin,points) #Point existence search
		unless (collision_check(r_origin,points))
			points << NousPoint.new(r_origin)
		end
		return points
	end
	
	def add_path(points)
		points.find_all { |n| n.pathable && !n.source}.each do |t| 
			points.find(&:source).path_to << t
			t.path_from << points.find(&:source)
		end
		return points
	end
	
	def collision_check(r_origin,points)
			return true if points.any? { |n| r_origin == n.origin }
	end
	
	def select_points(box,points) #Select points with the select tool
		UI::point_list_model.clear
		UI::prop_mod.text = ""
		box_origin = [box[0],box[1]] #box is an array with 4 values
		points.each do |n|
			if check_bounds(n.origin,box)
					 n.select
			elsif check_bounds(box_origin,n.bounds)
					 n.select
			else 
				n.deselect
				UI::point_list_model.clear
				UI::prop_mod.text = ""
			end
		end
		populate_prop(points)
		return points
	end
	
	def populate_prop (points)
		UI::point_list_model.clear
		UI::prop_mod.text = ""
		point = nil
		point = points.find(&:selected) if points.find_all(&:selected).length == 1
		if point
		  prop_vals = [point.note,
			             point.velocity,
									 point.duration,
									 point.channel,
									 point.x,
									 point.y,
									 color_to_hex(point.default_color),
									 point.path_mode,
									 point.signal_start]
			@prop_names.each	do |v|
				iter = UI::point_list_model.append
				iter[0] = v
				iter[1] = prop_vals[@prop_names.find_index(v)].to_s
			end
		elsif points.find_all(&:selected).length > 1
			UI::point_list_model.clear
			UI::prop_mod.text = ""
		end
	end	
	def point_list_select(selected)
		return if selected == nil
		@curr_prop = selected[0]
		if   selected[1][0] == "#"
			   UI::prop_mod.text = selected[1][1..6]
		else UI::prop_mod.text = selected[1]
		end
		UI::prop_mod.position = 0
		UI::prop_mod.grab_focus
	end
	
	def check_input(text)
		case @curr_prop
			when "Note", "Velocity"
				if text.to_i >= 1 && text.to_i <= 127
						 UI::prop_mod_button.sensitive = true
				else UI::prop_mod_button.sensitive = false
				end
			when "Duration (%)"
				if text.to_i >= 1 && text.to_i <= 100
						 UI::prop_mod_button.sensitive = true
				else UI::prop_mod_button.sensitive = false
				end
			when "Channel"
				if text.to_i >= 1 && text.to_i <= 16
					   UI::prop_mod_button.sensitive = true
				else UI::prop_mod_button.sensitive = false
				end
			when "X-coordinate", "Y-coordinate"
				if round_num_to_grid(text.to_i) >= 50 && round_num_to_grid(text.to_i) <= 3250
						 UI::prop_mod_button.sensitive = true
				else UI::prop_mod_button.sensitive = false
				end
			when "Color"
				if text.match(/^[0-9A-Fa-f]{6}$/)
					   UI::prop_mod_button.sensitive = true
				else UI::prop_mod_button.sensitive = false
				end
			when "Path Mode"
				if text == "horz" || text == "vert"
						 UI::prop_mod_button.sensitive = true
				else UI::prop_mod_button.sensitive = false
				end
			when "Signal Start"
				if text == "true" || text == "false"
					   UI::prop_mod_button.sensitive = true
				else UI::prop_mod_button.sensitive = false
				end
			else UI::prop_mod_button.sensitive = false
		end
	end
	
	def modify_properties(points)
		case @curr_prop
			when "Note"
				points.find(&:selected).note = UI::prop_mod.text.to_i
			when "Velocity"
				points.find(&:selected).velocity = UI::prop_mod.text.to_i
			when "Duration (%)"
				points.find(&:selected).duration = UI::prop_mod.text.to_i
			when "Channel"
				points.find(&:selected).channel = UI::prop_mod.text.to_i
			when "X-coordinate"
				points.find(&:selected).x = UI::prop_mod.text.to_i
			when "Y-coordinate"
				points.find(&:selected).y = UI::prop_mod.text.to_i
			when "Color"
				points.find(&:selected).set_default_color(hex_to_color("##{UI::prop_mod.text}"))
			when "Path Mode"
				points.find(&:selected).path_mode = UI::prop_mod.text
			when "Signal Start"
				case UI::prop_mod.text
					when "true"
						points.find(&:selected).signal_start = true
					when "false"
						points.find(&:selected).signal_start = false
				end
		end
		return points
	end
	
	def select_path_point(origin,points,source_chosen)
		points.find_all {|g| check_bounds(origin,g.bounds)}.each do |n|
			case !n.pathable
				when true #If clicking where a non-pathable point is
					source_chosen = n.path_set(source_chosen)
				when false
					if n.source
						points, source_chosen = cancel_path(points)
					end
					n.path_unset
			end
		end
		return points, source_chosen
	end
	
	def cancel_selected(points)
		points.find_all(&:selected).each { |n| n.deselect }
		return points
	end
	def cancel_path(points)
		points.find_all(&:pathable).each { |n| n.path_unset }
		return points, false
	end
	
	def delete_points(points)
		points.find_all {|f| !f.path_to.length.zero?}.each   {|n| n.path_to.reject!(&:selected)}
		points.find_all {|f| !f.path_from.length.zero?}.each {|n| n.path_from.reject!(&:selected)}
		points.reject!(&:selected)
		UI::point_list_model.clear
		UI::prop_mod.text = ""
		return points
	end
	
	def move_points(diff,points)
		if move_check(diff,points)
			points.find_all(&:selected).each {|n| n.set_destination(diff) }	
			UI::point_list_model.clear
			UI::prop_mod.text = ""
			populate_prop(points)			
		end
		return points
	end
	def move_check(diff,points)
		points.find_all(&:selected).each do |n|
			dest = n.origin.map
			dest = dest.to_a
			dest.map! {|g| g += diff[dest.find_index(g)]}
			return false if points.find_all(&:not_selected).any? { |g| g.origin == dest}
		end
		return true
	end
	
end

class NousPoint
	attr_accessor :source, :color, :path_to, :path_from, :note, :x, :y,
	              :velocity, :duration, :default_color, :path_mode, 
								:signal_start, :channel
	attr_reader :selected, :pathable, :origin, :bounds
	
	def initialize(o) #where the point was initially placed
		@dp = [4,8,10,12,14,16,20]
		
		@x = o[0]
		@y = o[1]
		@origin = o
		@bounds = [@x-@dp[5],@y-@dp[5],@x+@dp[5],@y+@dp[5]]
		@color          = GREY #point color defaults to gray++
		@path_color     = CYAN
		@default_color  = GREY
		@note           = 60     #all notes start at middle c
		@velocity       = 100		 #       ``       with 100 velocity
		@duration       = 100    #       ``       at a length (%) of the path length
		@channel        = 1      #       ``       assigned to midi channel 1 (instrument 1, but we will refer to them as channels, not instruments)
		@signal_start   = false
		@pathable       = false
		@selected       = false
		@source         = false
		@path_to        = [] #array of references to points that are receiving a path from this point
		@path_from      = [] #array of references to points that are sending   a path to   this point
		@path_mode      = "horz"
	end

	def not_selected
		!@selected
	end
	def not_pathable
		!@pathable
	end
	
	def origin=(o) #sets the origin of the point explicitly
		@x = o[0]
		@y = o[1]
		@origin = o
		@bounds = [@x-@dp[5],@y-@dp[5],@x+@dp[5],@y+@dp[5]]
	end

	def path_set(source_chosen)
		@pathable = true
		case source_chosen
			when false       #if source point was not chosen (first point clicked on path screen)
				@source = true #Path source is now chosen on this node
				@color = CYAN
				return true
			when true	       #Path source is already chosen in this operation
				@color = GREEN
		end
		return source_chosen
	end
	def path_unset
		@pathable = false
		@source = false
		@color = @default_color
	end

	def set_default_color(c)
		@color = c
		@default_color = c
	end
	def set_destination(diff) #sets a new origin for the point based on x,y coordinate differences
		@x += diff[0]
		@y += diff[1]
		@origin = [@x,@y]
		@bounds = [@x-@dp[5],@y-@dp[5],@x+@dp[5],@y+@dp[5]]
	end
	def select  #elevate color to denote 'selected' and sets a flag
		@selected = true
	end
	def deselect #resets the color from elevated 'selected' values and sets a flag
		@selected = false
		@color = @default_color
	end
	
	def draw(cr)                     #point will always be drawn to this specification.
		cr.set_source_rgba(@color[0],@color[1],@color[2],0.4)
		if @signal_start
			signal_start_draw(cr)
		else
			cr.rounded_rectangle(@x-@dp[1],@y-@dp[1],@dp[5],@dp[5],2,2) #slightly smaller rectangle adds 'relief' effect
		end
		cr.fill
		
		cr.set_source_rgba(@color[0],@color[1],@color[2],1)
		cr.circle(@x,@y,1)
		cr.fill
		
		if !@selected
			if @signal_start
				signal_start_draw(cr)
			else
				cr.rounded_rectangle(@x-@dp[2],@y-@dp[2],@dp[6],@dp[6],2,2)
			end
		end
		if @selected
			cr.set_source_rgba(1,1,1,0.8)
			if @signal_start			
				signal_start_draw(cr)
			else
				cr.rounded_rectangle(@x-@dp[2],@y-@dp[2],@dp[6],@dp[6],2,2) #a slightly smaller rectangle adds 'relief' effect
			end
			selection_caret_draw(cr)
		end
		cr.set_line_width(2)
		cr.stroke
	end
	
	def path_draw(cr)
		cr.set_source_rgba(@path_color[0],@path_color[1],@path_color[2],0.6)
		@path_to.each   {|t| trace_path_to(cr,t)}
		cr.set_line_cap(1)    #Round
		cr.set_line_join(2)   #Miter
		cr.set_line_width(5)
		cr.stroke
		if !@selected
			@path_to.each   {|t| trace_path_to(cr,t)}
			cr.set_source_rgba(0,0,0,0.4)
			cr.set_line_width(3)
			cr.stroke
		elsif @selected
			cr.set_source_rgba(ORNGE[0],ORNGE[1],ORNGE[2],0.4)
			@path_from.each {|s| trace_path_from(cr,s)}
			cr.set_line_width(3)
			cr.stroke
			cr.set_source_rgba(@path_color[0],@path_color[1],@path_color[2],0.4) if @selected
			@path_to.each   {|t| trace_path_to(cr,t)}
			cr.set_line_width(3)
			cr.stroke
		end
	end
	def signal_start_draw(cr)
		cr.move_to(@x-@dp[0],@y-@dp[3])
		cr.line_to(@x+@dp[0],@y-@dp[3])
		cr.line_to(@x+@dp[1],@y-@dp[1])
		cr.line_to(@x+@dp[1],@y+@dp[1])
		cr.line_to(@x+@dp[0],@y+@dp[3])
		cr.line_to(@x-@dp[0],@y+@dp[3])
		cr.line_to(@x-@dp[1],@y+@dp[1])
		cr.line_to(@x-@dp[1],@y-@dp[1])
		cr.line_to(@x-@dp[0],@y-@dp[3])
	end
	def selection_caret_draw(cr)
		cr.move_to(@x-@dp[4],@y-@dp[4])
		cr.line_to(@x-@dp[2],@y-@dp[4])
		cr.move_to(@x-@dp[4],@y-@dp[4])
		cr.line_to(@x-@dp[4],@y-@dp[2])

		cr.move_to(@x+@dp[4],@y-@dp[4])
		cr.line_to(@x+@dp[2],@y-@dp[4])
		cr.move_to(@x+@dp[4],@y-@dp[4])
		cr.line_to(@x+@dp[4],@y-@dp[2])
					
		cr.move_to(@x-@dp[4],@y+@dp[4])
		cr.line_to(@x-@dp[2],@y+@dp[4])
		cr.move_to(@x-@dp[4],@y+@dp[4])
		cr.line_to(@x-@dp[4],@y+@dp[2])
					
		cr.move_to(@x+@dp[4],@y+@dp[4])
		cr.line_to(@x+@dp[2],@y+@dp[4])
		cr.move_to(@x+@dp[4],@y+@dp[4])
		cr.line_to(@x+@dp[4],@y+@dp[2])
	end
	def trace_path_to(cr,t)
		case @path_mode
		when "horz"
			cr.move_to(@x,@y)
			cr.line_to(t.x,@y)
			cr.line_to(t.x,t.y)
		when "vert"
			cr.move_to(@x,@y)
			cr.line_to(@x,t.y)
			cr.line_to(t.x,t.y)
		when "line"
			cr.move_to(@x,@y)
			cr.line_to(t.x,t.y)
		end
	end	
	def trace_path_from(cr,s)
		case s.path_mode
		when "horz"
			cr.move_to(s.x,s.y)
			cr.line_to(@x,s.y)
			cr.line_to(@x,@y)
		when "vert"
			cr.move_to(s.x,s.y)
			cr.line_to(s.x,@y)
			cr.line_to(@x,@y)
		when "line"
			cr.move_to(s.x,s.y)
			cr.line_to(@x,@y)
		end
	end
end

Pl = Point_Logic.new