extends Node

const PORT = 7777
const MAX_PLAYERS = 4

var player_scene: PackedScene
var players_node: Node2D

func _ready():
	player_scene = preload("res://player.tscn")
	players_node = get_node("../Players")
	
	# 시그널 연결
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)

# ========== 서버/클라이언트 시작 ==========

func host_game():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_PLAYERS)
	if error != OK:
		print("서버 생성 실패: ", error)
		return false
	
	multiplayer.multiplayer_peer = peer
	print("서버 시작! ID: 1, 포트: ", PORT)
	
	# 서버 자신의 플레이어 스폰
	_spawn_player(1)
	return true

func join_game(ip: String):
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, PORT)
	if error != OK:
		print("연결 실패: ", error)
		return false
	
	multiplayer.multiplayer_peer = peer
	print("연결 시도 중... IP: ", ip)
	return true

# ========== 시그널 핸들러 ==========

func _on_peer_connected(id: int):
	# 서버만 새 플레이어 스폰 처리
	if multiplayer.is_server():
		print("피어 접속: ", id)
		# 새로 접속한 클라이언트에게 기존 플레이어들 알려주기
		for player in players_node.get_children():
			var player_id = player.name.to_int()
			_spawn_player_remote.rpc_id(id, player_id, player.position)
		
		# 새 플레이어 스폰 (모든 피어에게)
		var spawn_pos = Vector2(randf_range(150, 650), randf_range(150, 450))
		_spawn_player(id, spawn_pos)
		_spawn_player_remote.rpc(id, spawn_pos)

func _on_peer_disconnected(id: int):
	print("피어 퇴장: ", id)
	_remove_player(id)
	if multiplayer.is_server():
		_remove_player_remote.rpc(id)

func _on_connected_to_server():
	print("서버 연결 성공! 내 ID: ", multiplayer.get_unique_id())

func _on_connection_failed():
	print("서버 연결 실패!")
	multiplayer.multiplayer_peer = null

# ========== 플레이어 스폰/제거 ==========

func _spawn_player(id: int, pos: Vector2 = Vector2.ZERO):
	if players_node.has_node(str(id)):
		return  # 이미 존재하면 무시
	
	var player = player_scene.instantiate()
	player.name = str(id)
	if pos == Vector2.ZERO:
		pos = Vector2(randf_range(150, 650), randf_range(150, 450))
	player.position = pos
	players_node.add_child(player)
	print("플레이어 스폰: ", id, " 위치: ", pos)

func _remove_player(id: int):
	var player = players_node.get_node_or_null(str(id))
	if player:
		player.queue_free()
		print("플레이어 제거: ", id)

# ========== RPC 함수들 ==========

@rpc("authority", "call_remote", "reliable")
func _spawn_player_remote(id: int, pos: Vector2):
	_spawn_player(id, pos)

@rpc("authority", "call_remote", "reliable")
func _remove_player_remote(id: int):
	_remove_player(id)
