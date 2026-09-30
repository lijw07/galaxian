class_name SoundSynth
extends RefCounted

const MIX_RATE := 22050
const PEAK := 32767.0
const MELODY_AMPLITUDE := 0.5


static func sweep(start_hz: float, end_hz: float, duration: float, square: bool) -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	var count := int(duration * MIX_RATE)
	var phase := 0.0
	for index in count:
		var progress := float(index) / count
		phase += lerpf(start_hz, end_hz, progress) / MIX_RATE
		samples.append(_wave(phase, square) * (1.0 - progress))
	return _to_stream(samples, false)


static func noise(duration: float, smoothing: float) -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	var count := int(duration * MIX_RATE)
	var value := 0.0
	for index in count:
		var progress := float(index) / count
		value = lerpf(value, randf_range(-1.0, 1.0), smoothing)
		samples.append(value * pow(1.0 - progress, 2.0))
	return _to_stream(samples, false)


static func melody(frequencies: PackedFloat32Array, note_duration: float) -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	var note_length := int(note_duration * MIX_RATE)
	for frequency in frequencies:
		for index in note_length:
			var envelope := 1.0 - float(index) / note_length
			samples.append(_wave(frequency * index / MIX_RATE, true) * envelope * MELODY_AMPLITUDE)
	return _to_stream(samples, false)


static func drone(base_hz: float, depth_hz: float, period: float) -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	var count := int(period * MIX_RATE)
	var phase := 0.0
	for index in count:
		var progress := float(index) / count
		phase += (base_hz + depth_hz * sin(TAU * progress)) / MIX_RATE
		samples.append(_wave(phase, false))
	return _to_stream(samples, true)


static func _wave(phase: float, square: bool) -> float:
	var sine := sin(TAU * phase)
	return signf(sine) if square else sine


static func _to_stream(samples: PackedFloat32Array, looping: bool) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for index in samples.size():
		bytes.encode_s16(index * 2, int(clampf(samples[index], -1.0, 1.0) * PEAK))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	if looping:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = samples.size()
	return stream
