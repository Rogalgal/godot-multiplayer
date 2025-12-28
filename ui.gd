extends Control

@onready var network = get_node("/root/Main/NetworkManager")
@onready var ip_input: LineEdit = $Panel/VBox/IPInput
@onready var status_label: Label = $Panel/VBox/StatusLabel
@onready var host_btn: Button = $Panel/VBox/HostButton
@onready var join_btn: Button = $Panel/VBox/JoinButton

func _ready():
	host_btn.pressed.connect(_on_host_pressed)
	join_btn.pressed.connect(_on_join_pressed)
	
	# 연결 상태 시그널
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_failed)
	multiplayer.peer_connected.connect(func(_id): _update_status())
	multiplayer.peer_disconnected.connect(func(_id): _update_status())

func _on_host_pressed():
	if network.host_game():
		status_label.text = "호스팅 중..."
		_disable_buttons()
		_update_status()

func _on_join_pressed():
	if network.join_game(ip_input.text):
		status_label.text = "연결 중..."
		_disable_buttons()

func _on_connected():
	_update_status()

func _on_failed():
	status_label.text = "연결 실패!"
	_enable_buttons()

func _disable_buttons():
	host_btn.disabled = true
	join_btn.disabled = true
	ip_input.editable = false

func _enable_buttons():
	host_btn.disabled = false
	join_btn.disabled = false
	ip_input.editable = true

func _update_status():
	var players = get_node("/root/Main/Players")
	var count = players.get_child_count()
	var my_id = multiplayer.get_unique_id()
	var role = "서버" if multiplayer.is_server() else "클라이언트"
	status_label.text = "%s (ID: %d)\n플레이어: %d명" % [role, my_id, count]
