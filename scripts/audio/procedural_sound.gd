class_name ProceduralSound
extends RefCounted
## Original simple synthesized tones, no external recordings.
static func tone(frequency: float, duration: float, level: float, looping: bool = false) -> AudioStreamWAV:
 var rate := 11025
 var samples := int(duration * rate)
 var bytes := PackedByteArray()
 bytes.resize(samples * 2)
 for i: int in range(samples):
  var time := float(i) / float(rate)
  var envelope := 1.0 if looping else sin(PI * float(i) / float(samples))
  var sample := sin(TAU * frequency * time) * 0.7 + sin(TAU * frequency * 2.0 * time) * 0.3
  bytes.encode_s16(i * 2, int(clampf(sample * envelope * level, -1.0, 1.0) * 32767))
 var stream := AudioStreamWAV.new()
 stream.format = AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate = rate
 stream.stereo = false
 stream.data = bytes
 if looping:
  stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
  stream.loop_begin = 0
  stream.loop_end = samples
 return stream
