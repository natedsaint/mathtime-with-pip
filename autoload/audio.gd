extends Node
## Sound effects. Every sound is a tiny chiptune made in code (no files needed),
## to match Pip's pixel look. To swap one out, drop a file named like the keys
## below into res://assets/sfx/ (e.g. correct.ogg or correct.wav) and it's used instead.
##
## The "try_again" sound is deliberately soft and curious, never a buzzer.

const RATE := 22050
const PLAYERS := 6
const FILE_DIR := "res://assets/sfx/"

## Each sound: list of notes [frequency Hz (0 = rest), seconds], a waveform, and volume.
const SOUNDS := {
	"tap": {"notes": [[1320, 0.03]], "wave": "square", "volume": 0.06, "decay": 40.0},
	"correct": {"notes": [[784, 0.07], [1175, 0.16]], "wave": "square", "volume": 0.12, "decay": 9.0},
	"streak": {"notes": [[523, 0.07], [659, 0.07], [784, 0.07], [1047, 0.07], [1319, 0.28]],
		"wave": "square", "volume": 0.12, "decay": 6.0},
	"try_again": {"notes": [[392, 0.1], [494, 0.18]], "wave": "triangle", "volume": 0.22, "decay": 8.0},
	"reveal": {"notes": [[659, 0.12], [880, 0.3]], "wave": "triangle", "volume": 0.25, "decay": 5.0},
	"finish": {"notes": [[523, 0.1], [659, 0.1], [784, 0.1], [1047, 0.4]],
		"wave": "square", "volume": 0.12, "decay": 4.0},
	"poke": {"notes": [[523, 0.05], [784, 0.05], [1047, 0.12]], "wave": "triangle", "volume": 0.25, "decay": 10.0},
	"dizzy": {"notes": [[1319, 0.07], [1047, 0.07], [880, 0.07], [698, 0.07], [587, 0.07], [523, 0.25]],
		"wave": "triangle", "volume": 0.25, "decay": 4.0},
	"record": {"notes": [[523, 0.09], [523, 0.09], [784, 0.09], [1047, 0.18], [0, 0.06], [988, 0.09], [1047, 0.5]],
		"wave": "square", "volume": 0.13, "decay": 3.0},
}

var muted := false
var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	for i in PLAYERS:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	for sound_name in SOUNDS:
		_streams[sound_name] = _load_file(sound_name)
		if _streams[sound_name] == null:
			_streams[sound_name] = _synth(SOUNDS[sound_name])
	muted = bool(SaveData.cfg.get_value("settings", "muted", false))


func play(sound_name: String) -> void:
	if muted or not _streams.has(sound_name):
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _streams[sound_name]
	p.play()


func set_muted(value: bool) -> void:
	muted = value
	SaveData.cfg.set_value("settings", "muted", value)
	SaveData.save()


func _load_file(sound_name: String) -> AudioStream:
	for ext in ["ogg", "wav", "mp3"]:
		var path: String = FILE_DIR + sound_name + "." + ext
		if ResourceLoader.exists(path):
			return load(path)
	return null


## Builds a 16-bit mono AudioStreamWAV from a note list.
func _synth(spec: Dictionary) -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	var phase := 0.0
	for note in spec["notes"]:
		var freq: float = note[0]
		var count := int(note[1] * RATE)
		for i in count:
			var t := float(i) / RATE
			var v := 0.0
			if freq > 0.0:
				phase = fmod(phase + freq / RATE, 1.0)
				v = _wave(spec["wave"], phase)
				var attack := minf(t / 0.004, 1.0)
				var release := minf((count - i) / (0.01 * RATE), 1.0) # avoid clicks
				v *= attack * release * exp(-t * spec["decay"])
			samples.append(v * spec["volume"])
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	return stream


func _wave(kind: String, phase: float) -> float:
	match kind:
		"triangle":
			return 4.0 * absf(phase - 0.5) - 1.0
		_:
			return 1.0 if phase < 0.5 else -1.0
