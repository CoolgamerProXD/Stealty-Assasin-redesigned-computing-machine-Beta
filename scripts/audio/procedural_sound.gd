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
static func footstep(surface: String = "stone") -> AudioStreamWAV:
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
  var frequency := 72.0 if surface == "carpet" else (105.0 if surface == "wood" else (64.0 if surface == "grass" else 88.0))
  var amount := 0.09 if surface in ["carpet", "grass"] else 0.14
  var sound := (filtered * 0.65 + sin(TAU * frequency * t) * 0.35) * fade * amount
  bytes.encode_s16(i * 2, int(clampf(sound, -1.0, 1.0) * 32767))
 var stream := AudioStreamWAV.new()
 stream.format = AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate = rate
 stream.stereo = false
 stream.data = bytes
 return stream

# Quiet, original synthesized beds: no recordings or simulated dialogue.
# A short overlap makes the deterministic filtered-noise loop continuous.
static var ambient_cache: Dictionary = {}

static func ambience(kind: String) -> AudioStreamWAV:
 if ambient_cache.has(kind): return ambient_cache[kind]
 var rate := 11025
 var count := rate * 6
 var overlap := rate / 4
 var loop_length: int = count - overlap
 var raw := PackedFloat32Array()
 raw.resize(count)
 var state: int = 41041
 var filtered := 0.0
 var follow := 0.025 if kind == "mountain" else (0.06 if kind == "city" else 0.04)
 var tone_frequency := 54.0 if kind == "station" else (42.0 if kind == "hotel" else (64.0 if kind == "initiation" else 36.0))
 for i: int in range(count):
  state = (state * 1103515245 + 12345) & 0x7fffffff
  var noise := float(state % 65536) / 32768.0 - 1.0
  filtered = lerpf(filtered, noise, follow)
  var t := float(i) / float(rate)
  var motion := 0.75 + 0.25 * sin(TAU * 0.16 * t)
  raw[i] = filtered * motion * 0.040 + sin(TAU * tone_frequency * t) * 0.002
 var bytes := PackedByteArray()
 bytes.resize(loop_length * 2)
 for i: int in range(loop_length):
  var sample := raw[i]
  if i < overlap: sample = lerpf(raw[loop_length+i], raw[i], float(i) / float(overlap))
  bytes.encode_s16(i*2, int(clampf(sample,-1.0,1.0)*32767))
 var stream := AudioStreamWAV.new()
 stream.format = AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate = rate
 stream.stereo = false
 stream.data = bytes
 stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
 stream.loop_begin = 0
 stream.loop_end = loop_length
 ambient_cache[kind] = stream
 return stream
