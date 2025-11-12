extends Node

var bgm_gameplay: AudioStream
var bgm_mainmenu: AudioStream
var enemy_die: AudioStream
var enemy_spawn: AudioStream
var enemy_hit: AudioStream
var type_correct: AudioStream
var type_wrong: AudioStream
var typing_1: AudioStream
var typing_2: AudioStream

var base_hit: AudioStream
var notif_win: AudioStream
var notif_lose: AudioStream
var tower_deploy: AudioStream
var tower_retreat: AudioStream
var tower_skill : AudioStream
var tower_dead: AudioStream

var bgm_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS = 16

var master_volume: float = 1.0
var bgm_volume: float = 0.7
var sfx_volume: float = 0.8

var current_bgm: String = ""

func _ready() -> void:
	bgm_gameplay = load("res://asset/Audio/BGM Gameplay.wav")
	bgm_gameplay.loop_mode = AudioStreamWAV.LOOP_FORWARD
	bgm_mainmenu = load("res://asset/Audio/BGM MainMenu.wav")
	bgm_mainmenu.loop_mode = AudioStreamWAV.LOOP_FORWARD
	enemy_die = load("res://asset/Audio/Sfx/Enemy/EnemyDie.wav")
	enemy_spawn = load("res://asset/Audio/Sfx/Enemy/Enemy Spawn.wav")
	enemy_hit = load("res://asset/Audio/Sfx/Enemy/Enemy Hit Tower.wav")
	type_correct = load("res://asset/Audio/Sfx/Typing/Correct.wav")
	type_wrong = load("res://asset/Audio/Sfx/Typing/Wrong.wav")
	typing_1 = load("res://asset/Audio/Sfx/Typing/Typing 1.wav")
	typing_2 = load("res://asset/Audio/Sfx/Typing/Typing 2.wav")
	base_hit = load("res://asset/Audio/Base get Hit.wav")
	notif_win = load("res://asset/Audio/notif win-lose/notifier Win mastering.wav")
	notif_lose = load("res://asset/Audio/notif win-lose/Notifier lose mastering.wav")
	tower_deploy = load("res://asset/Audio/Tower/Tower Deploy Spawn .wav")
	tower_retreat = load("res://asset/Audio/Tower/Tarik Tower.wav")
	tower_skill = load("res://asset/Audio/Tower/Activate Skill.wav")
	tower_dead = load("res://asset/Audio/Tower/Drop dead.wav")
	
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Master"
	add_child(bgm_player)
	
	for i in MAX_SFX_PLAYERS:
		var player = AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		sfx_players.append(player)
	
	print("AudioManager initialized with ", MAX_SFX_PLAYERS, " SFX channels")

func play_bgm(bgm_name: String, fade_duration: float = 1.0) -> void:
	var stream: AudioStream = null
	
	match bgm_name.to_lower():
		"gameplay":
			stream = bgm_gameplay
		"mainmenu":
			stream = bgm_mainmenu
		_:
			push_error("Unknown BGM: " + bgm_name)
			return
	
	if stream == null:
		push_error("BGM stream is null: " + bgm_name)
		return
	
	if current_bgm == bgm_name and bgm_player.playing:
		return
	
	current_bgm = bgm_name
	bgm_player.stream = stream
	bgm_player.volume_db = linear_to_db(bgm_volume * master_volume)
	bgm_player.play()

func stop_bgm(fade_duration: float = 1.0) -> void:
	if bgm_player.playing:
		bgm_player.stop()
	current_bgm = ""

func play_sfx(sfx_name: String, pitch_scale: float = 1.0) -> void:
	var stream: AudioStream = null
	
	match sfx_name.to_lower():
		"base_hit":
			stream = base_hit
		"notif_win":
			stream = notif_win
		"notif_lose":
			stream = notif_lose
		"tower_deploy":
			stream = tower_deploy
		"tower_retreat":
			stream = tower_retreat
		"tower_skill":
			stream = tower_skill
		"tower_dead":
			stream = tower_dead
		"enemy_die":
			stream = enemy_die
		"enemy_spawn":
			stream = enemy_spawn
		"enemy_hit":
			stream = enemy_hit
		"type_correct":
			stream = type_correct
		"type_wrong":
			stream = type_wrong
		"typing_1":
			stream = typing_1
		"typing_2":
			stream = typing_2
		"typing_random":
			stream = typing_1 if randf() > 0.5 else typing_2
		_:
			push_error("Unknown SFX: " + sfx_name)
			return
	
	if stream == null:
		push_error("SFX stream is null: " + sfx_name)
		return
	
	var player = get_available_sfx_player()
	if player:
		player.stream = stream
		player.volume_db = linear_to_db(sfx_volume * master_volume)
		player.pitch_scale = pitch_scale
		player.play()

func get_available_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	return sfx_players[0]

## Set master volume (0.0 to 1.0)
func set_master_volume(volume: float) -> void:
	master_volume = clamp(volume, 0.0, 1.0)
	_update_volumes()

## Set BGM volume (0.0 to 1.0)
func set_bgm_volume(volume: float) -> void:
	bgm_volume = clamp(volume, 0.0, 1.0)
	bgm_player.volume_db = linear_to_db(bgm_volume * master_volume)

## Set SFX volume (0.0 to 1.0)
func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)

## Update all volumes
func _update_volumes() -> void:
	bgm_player.volume_db = linear_to_db(bgm_volume * master_volume)

## Convert linear volume to decibels
func linear_to_db(linear: float) -> float:
	if linear <= 0:
		return -80.0
	return 20.0 * log(linear) / log(10.0)
