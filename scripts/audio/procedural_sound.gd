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

# A soft original synthesized footfall with a short filtered-noise transient.
# No sampled recordings or external sound assets are used.
static func footstep() -> AudioStreamWAV:
 var rate := 11025
 var count := int(0.12 * rate)
 var bytes := PackedByteArray()
 bytes.resize(count * 2)
 var state: int = 51273
 var filtered := 0.0
 for i: int in range(count):
  state = (state * 1103515245 + 12345) & 0x7fffffff
  var noise := float(state % 65536) / 32768.0 - 1.0
  filtered = lerpf(filtered, noise, 0.16)
  var t := float(i) / float(rate)
  var fade := exp(-t * 35.0) * minf(t * 120.0, 1.0)
  var sound := (filtered * 0.65 + sin(TAU * 83.0 * t) * 0.35) * fade * 0.14
  bytes.encode_s16(i * 2, int(clampf(sound, -1.0, 1.0) * 32767))
 var stream := AudioStreamWAV.new()
 stream.format = AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate = rate
 stream.stereo = false
 stream.data = bytes
 return stream
