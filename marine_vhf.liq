#!/usr/local/bin/liquidsoap -v

#set("log.stdout",true)
#set("log.file.path","/tmp/<script>.log")

set("harbor.bind_addr","0.0.0.0")
set("harbor.max_connections",10)

# MP3 File destination
output_dir = "/mnt/radio/audio"

# Input and output stream passwords
input_pass = "50urc3!"
output_pass = "my_secure_password"

# Continuous silence / squelch detection time in seconds to trigger end of file.  [Must be float]
sq_time = 5.0


# Create sNN safe sources from MP3 input streams to allow sources to connect / disconnect without breaking
# Listen on port 8080 away from Icecast default of 8000 
s6 = mksafe(input.harbor(id="VHF6","VHF6.mp3",port=8080,password=input_pass))
s12 = mksafe(input.harbor(id="VHF12","VHF12.mp3",port=8080,password=input_pass))
s16 = mksafe(input.harbor(id="VHF16","VHF16.mp3",port=8080,password=input_pass))
s20a = mksafe(input.harbor(id="VHF20A","VHF20A.mp3",port=8080,password=input_pass))
s20b = mksafe(input.harbor(id="VHF20B","VHF20B.mp3",port=8080,password=input_pass))
s82a = mksafe(input.harbor(id="VHF82A","VHF82A.mp3",port=8080,password=input_pass))
s82b = mksafe(input.harbor(id="VHF82B","VHF82B.mp3",port=8080,password=input_pass))

# Create bNN fallible sources using silence period to detect squelch for recording
b6 = strip_blank(max_blank=sq_time, min_noise=0.0, s6)
b12 = strip_blank(max_blank=sq_time, min_noise=0.0, s12)
b16 = strip_blank(max_blank=sq_time, min_noise=0.0, s16)
b20a = strip_blank(max_blank=sq_time, min_noise=0.0, s20a)
b20b = strip_blank(max_blank=sq_time, min_noise=0.0, s20b)
b82a = strip_blank(max_blank=sq_time, min_noise=0.0, s82a)
b82b = strip_blank(max_blank=sq_time, min_noise=0.0, s82b)

# Output squelched MP3 files - timestamped files in directories organised by date and channel
output.file(%mp3.vbr(stereo=false,quality=4,samplerate=22050), "#{output_dir}/%Y-%m-%d/VHF6/%Y%m%d_%H%M%S_VHF6.mp3", append=true,flush=true,fallible=true,b6)
output.file(%mp3.vbr(stereo=false,quality=4,samplerate=22050), "#{output_dir}/%Y-%m-%d/VHF12/%Y%m%d_%H%M%S_VHF12.mp3", append=true,flush=true,fallible=true,b12)
output.file(%mp3.vbr(stereo=false,quality=4,samplerate=22050), "#{output_dir}/%Y-%m-%d/VHF16/%Y%m%d_%H%M%S_VHF16.mp3", append=true,flush=true,fallible=true,b16)

# Same but separate files for VHF 20 and 82 duplex A/B, saved in same directory
output.file(%mp3.vbr(stereo=false,quality=4,samplerate=22050), "#{output_dir}/%Y-%m-%d/VHF20/%Y%m%d_%H%M%S_VHF20A.mp3", append=true,flush=true,fallible=true,b20a)
output.file(%mp3.vbr(stereo=false,quality=4,samplerate=22050), "#{output_dir}/%Y-%m-%d/VHF20/%Y%m%d_%H%M%S_VHF20B.mp3", append=true,flush=true,fallible=true,b20b)
output.file(%mp3.vbr(stereo=false,quality=4,samplerate=22050), "#{output_dir}/%Y-%m-%d/VHF82/%Y%m%d_%H%M%S_VHF82A.mp3", append=true,flush=true,fallible=true,b82a)
output.file(%mp3.vbr(stereo=false,quality=4,samplerate=22050), "#{output_dir}/%Y-%m-%d/VHF82/%Y%m%d_%H%M%S_VHF82B.mp3", append=true,flush=true,fallible=true,b82b)

# Combine VHF 20 and 82 duplex channels for streaming
c20 = add([s20a,s20b])
c82 = add([s82a,s82b])

# Create combined 'all streams' output for streaming
harbour = add([s6,s12,s16,c20,c82])

# Create separate outputs to Icecast for each channel, plus combined output
output.icecast(%mp3(stereo=false), host="localhost",port=8000,password=output_pass,mount="VHF6.mp3",s6)
output.icecast(%mp3(stereo=false), host="localhost",port=8000,password=output_pass,mount="VHF12.mp3",s12)
output.icecast(%mp3(stereo=false), host="localhost",port=8000,password=output_pass,mount="VHF16.mp3",s16)
output.icecast(%mp3(stereo=false), host="localhost",port=8000,password=output_pass,mount="VHF20.mp3",c20)
output.icecast(%mp3(stereo=false), host="localhost",port=8000,password=output_pass,mount="VHF82.mp3",c82)
output.icecast(%mp3(stereo=false), host="localhost",port=8000,password=output_pass,mount="Harbour.mp3",harbour)


