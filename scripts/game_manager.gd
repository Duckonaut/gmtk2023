extends Node

var main_camera: MainCamera = null
var player: CritterBase = null

func _process(delta: float) -> void:
    var player_room_x: int = floori((player.global_position.x + 64) / 128)
    var player_room_y: int = floori((player.global_position.y + 64) / 128)
    
    main_camera.move_to(Vector2i(player_room_x, player_room_y))
