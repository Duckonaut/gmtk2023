extends CharacterBody2D
class_name CritterBase

const GRAVITY: float = 400.0

enum CritterAnimationState {
    IDLE,
    CROUCH,
    WALK,
    JUMP_UP,
    JUMP_MID,
    JUMP_DOWN,
    LAND,
}

const CRITTER_ANIMATION: Dictionary = {
    CritterAnimationState.IDLE: "idle",
    CritterAnimationState.CROUCH: "crouch",
    CritterAnimationState.WALK: "walk",
    CritterAnimationState.JUMP_UP: "jump_up",
    CritterAnimationState.JUMP_MID: "jump_mid",
    CritterAnimationState.JUMP_DOWN: "jump_down",
    CritterAnimationState.LAND: "land"
};

class CritterCalculatedData:
    const SPEED_MAX_MIN: float = 25.0
    const SPEED_MAX_MAX: float = 32.0
    const SPEED_DELTA_MIN: float = 50.0
    const SPEED_DELTA_MAX: float = 72.0
    const DRAG_MIN: float = 0.97
    const DRAG_MAX: float = 0.99
    const JUMP_MIN: float = 120.0
    const JUMP_MAX: float = 160.0

    var speed_max
    var speed_delta
    var drag
    var jump_strength
    
    static func create_from_properties(props: CritterProperties) -> CritterCalculatedData:
        var data = CritterCalculatedData.new()
        
        data.speed_max = lerpf(SPEED_MAX_MIN, SPEED_MAX_MAX, clampf((props.survival + props.cute / 2) / 7.5, 0.0, 1.0))
        data.speed_delta = lerpf(SPEED_DELTA_MIN, SPEED_DELTA_MAX, clampf((props.pathetic - props.cute / 2) / 2.5, 0.0, 1.0))
        data.drag = lerpf(DRAG_MIN, DRAG_MAX, clampf((props.pathetic - props.survival / 2) / 2.5, 0.0, 1.0))
        data.jump_strength = lerpf(JUMP_MIN, JUMP_MAX, clampf((props.cute - props.pathetic / 2) / 2.5, 0.0, 1.0))
        
        print("calculated props:")
        print("\tspeed_max: %f" % data.speed_max)
        print("\tspeed_delta: %f" % data.speed_delta)
        print("\tdrag: %f" % data.drag)
        print("\tjump_strength: %f" % data.jump_strength)
        return data     

@export var critter_properties: CritterProperties = null
var critter_data: CritterCalculatedData = null

var on_ground: bool = true
var crouch: bool = false
var anim_state: CritterAnimationState = CritterAnimationState.IDLE

# Node references
var sprite: Sprite2D = null
var animator: AnimationPlayer = null

func _ready() -> void:
    GameManager.player = self
    if critter_properties == null:
        push_error("critter needs a CritterProperties resource to gather data from!")
        return
    
    critter_data = CritterCalculatedData.create_from_properties(critter_properties)
    sprite = $Sprite2D
    animator = $AnimationPlayer

func _process(delta: float) -> void:
    anim_process(delta)

func _physics_process(delta: float) -> void:
    var left = Input.is_action_pressed("move_left")
    var right = Input.is_action_pressed("move_right")
    var jump = Input.is_action_just_pressed("move_jump")
    crouch = Input.is_action_pressed("move_crouch")
    
    if left:
        sprite.flip_h = true
        velocity.x -= critter_data.speed_delta
    if right:
        sprite.flip_h = false
        velocity.x += critter_data.speed_delta
    
    if on_ground:
        velocity.y = 0
        if jump:
            velocity.y -= critter_data.jump_strength
        else:
            velocity.x = clampf(velocity.x, -critter_data.speed_max, critter_data.speed_max)
    
            velocity.x = velocity.x * critter_data.drag
    else:
        velocity.y += GRAVITY * delta
        
        velocity.x = clampf(velocity.x, -critter_data.speed_max * 1.1, critter_data.speed_max * 1.1)
    
    
    if abs(velocity.x) < 8.0:
        velocity.x = 0
    
    move_and_slide()
    on_ground = is_on_floor()

func anim_process(delta: float) -> void:
    var anim_done: bool = !animator.is_playing()
    var old_state = anim_state
    if anim_state == CritterAnimationState.IDLE:
        if on_ground:
            if crouch:
                anim_state = CritterAnimationState.CROUCH
            elif abs(velocity.x) > 1.0:
                anim_state = CritterAnimationState.WALK
        else:
            if velocity.y < 0:
                anim_state = CritterAnimationState.JUMP_UP
            elif velocity.y >= 0:
                anim_state = CritterAnimationState.JUMP_DOWN

    elif anim_state == CritterAnimationState.WALK:
        if on_ground:
            if abs(velocity.x) < 1.0:
                anim_state = CritterAnimationState.IDLE
        else:
            if velocity.y < 10:
                anim_state = CritterAnimationState.JUMP_UP

    elif anim_state == CritterAnimationState.JUMP_UP:
        if velocity.y > -16:
            anim_state = CritterAnimationState.JUMP_MID
    elif anim_state == CritterAnimationState.JUMP_MID:
        if velocity.y > 16:
            anim_state = CritterAnimationState.JUMP_DOWN
    elif anim_state == CritterAnimationState.JUMP_DOWN:
        if on_ground:
            anim_state = CritterAnimationState.LAND
    elif anim_state == CritterAnimationState.LAND:
        if anim_done:
            anim_state = CritterAnimationState.IDLE
    
    if anim_state != old_state:
        animator.play("%s/%s" % [critter_properties.anim_prefix, CRITTER_ANIMATION[anim_state]])

            
