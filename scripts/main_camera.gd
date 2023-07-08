extends Camera2D

class_name MainCamera

const ROOM_SIZE: float = 128.0

var current_pos: Vector2i = Vector2i.ZERO
var last_pos: Vector2i = Vector2i.ZERO
var progress: float = 1.0

var transitioning: bool = false

func _ready() -> void:
    GameManager.main_camera = self

func smoothstepf(from: float, to: float, by: float) -> float:
    var y = by * by * (3.0 - 2.0 * by)
    
    return from + y * (to - from)

func vector_lerp(from: Vector2, to: Vector2, by: float) -> Vector2:
    var v: Vector2 = Vector2.ZERO

    v.x = smoothstepf(from.x, to.x, by)
    v.y = smoothstepf(from.y, to.y, by)
    
    return v

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    if transitioning:
        progress += delta * 4.0
        
        if progress > 0.995:
            progress = 1.0
            transitioning = false
    
        global_position = vector_lerp(Vector2(last_pos) * ROOM_SIZE, Vector2(current_pos) * ROOM_SIZE, progress)
        
        print("progress: %2.2f" % progress)

func move_to(pos: Vector2i):
    if pos == current_pos:
        return

    print("moving from %d, %d to %d, %d" % [current_pos.x, current_pos.y, pos.x, pos.y])
    
    transitioning = true
    if pos == last_pos:
        progress = 1.0 - progress
    else:
        progress = 0.0
    last_pos = current_pos
    current_pos = pos
    
