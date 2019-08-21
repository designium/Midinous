#Midi input and output methods go here

#Output.use(0) on windows will default to the Microsoft default synth
#Sends a series of notes to an instrument
class Proc_Midi

	#Sends a note to an instrument
	def note_send(note,port)
		out = UniMIDI::Output.use(port)
		out.puts(0x90,note,100)
	end

	#Release a note. Does not require a duration. Is called when a release signal is received.
	def note_rlse(note,port)
		out = UniMIDI::Output.use(port)
		out.puts(0x80,note,100)
	end

end

Pm = Proc_Midi.new