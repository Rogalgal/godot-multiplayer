extends CharacterBody2D

const SPEED = 300.0

@onready var sprite: ColorRect = $Sprite
@onready var label: Label = $Label
@onready var sync: MultiplayerSynchronizer = $MultiplayerSynchronizer

# 동기화할 위치 (@export 필수)
@export var sync_pos: Vector2 = Vector2.ZERO

func _ready():
	# 플레이어 ID는 노드 이름
	var player_id = name.to_int()
	
	# 이 플레이어의 authority 설정
	set_multiplayer_authority(player_id)
	
	# MultiplayerSynchronizer 설정 (코드에서 직접)
	_setup_synchronizer()
	
	sprite.color = Color.GREEN
	# 내 캐릭터인지에 따라 색상 구분
	if is_multiplayer_authority():
		label.text = "나 (ID: %d)" % player_id
	else:
		label.text = "ID: %d" % player_id
	
	sync_pos = position

func _setup_synchronizer():
	# SceneReplicationConfig를 코드에서 생성
	var config = SceneReplicationConfig.new()
	
	# sync_pos 변수를 동기화 대상으로 추가 (^":property" 형식)
	config.add_property(^":sync_pos")
	config.property_set_replication_mode(^":sync_pos", SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
	
	sync.replication_config = config

func _physics_process(delta):
	if is_multiplayer_authority():
		# 내 캐릭터: 입력 처리
		var input_dir = Vector2.ZERO
		input_dir.x = Input.get_axis("ui_left", "ui_right")
		input_dir.y = Input.get_axis("ui_up", "ui_down")
		
		velocity = input_dir.normalized() * SPEED
		move_and_slide()
		
		# 동기화용 변수 업데이트
		sync_pos = position
	else:
		# 다른 플레이어: 동기화된 위치로 보간
		position = position.lerp(sync_pos, 0.25)

func change_color():
	if sprite.color == Color.GREEN:
		sprite.color = Color.RED
	elif sprite.color == Color.RED:
		sprite.color = Color.BLUE
	else:
		sprite.color = Color.GREEN
