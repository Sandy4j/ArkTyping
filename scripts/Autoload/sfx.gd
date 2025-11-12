extends AudioStreamPlayer

@export var SFX:Array[AudioStreamWAV]

func play_skill_sfx():
	self.stream = SFX.get(0)
	self.play()

func play_death_sfx():
	self.stream = SFX.get(1)
	self.play()

func play_retreat_sfx():
	self.stream = SFX.get(2)
	self.play()

func play_deploy_sfx():
	self.stream = SFX.get(3)
	self.play()
