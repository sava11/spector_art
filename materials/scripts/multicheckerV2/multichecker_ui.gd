extends PanelContainer

## Spacing constant used for UI layout calculations.
const SPACE := 4

signal multichecker_changed(to:MulticheckerV2)

## Input action name used for menu activation.
const prompt_action: String = "ui_accept"

## Menu visibility state - controls whether the menu is displayed.
var showed: bool = false: set = set_showed

## Help prompt panel showing current key binding and description.
var prompt: HBoxContainer

## Main menu panel containing the button container.
var collection: ScrollContainer

## Texture displaying the current key binding for the prompt action.
var prompt_key_image: TextureRect

## Label displaying the current key binding for the prompt action.
var prompt_label: Label

## Label displaying the translated description text.
var prompt_desc_label: Label

## Horizontal container holding all menu option buttons.
var button_container: HBoxContainer

var current_multichecker:MulticheckerV2=null:set=set_multichecker

func _enter_tree() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	# Build help prompt UI
	#region prompt
	var mc:=MarginContainer.new()
	mc.name="mc"
	mc.set("theme_override_constants/margin_top",SPACE)
	mc.set("theme_override_constants/margin_left",SPACE)
	mc.set("theme_override_constants/margin_right",SPACE)
	mc.set("theme_override_constants/margin_bottom",SPACE)
	add_child(mc)
	prompt=HBoxContainer.new()
	prompt.name="prompt"
	prompt.set("theme_override_constants/separation",SPACE)
	mc.add_child(prompt)
	prompt_key_image=TextureRect.new()
	prompt_key_image.name="img"
	prompt_key_image.hide()
	prompt.add_child(prompt_key_image)
	prompt_label=Label.new()
	prompt_label.name="key"
	prompt.add_child(prompt_label)
	prompt_desc_label=Label.new()
	prompt_desc_label.name="desc"
	prompt.add_child(prompt_desc_label)
	prompt.hide()
	#endregion
	
	# Build main menu collection UI
	#region collection
	collection=ScrollContainer.new()
	collection.name="collection"
	collection.custom_minimum_size=Vector2(196,32)
	collection.draw_focus_border=true
	collection.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	mc.add_child(collection)
	button_container=HBoxContainer.new()
	button_container.name="button_container"
	button_container.set("theme_override_constants/separation",SPACE)
	collection.add_child(button_container)
	collection.hide()
	#endregion
	
	for b in button_container.get_children():
		b.queue_free()
	
	_changed_device()
	IV.input_changed.connect(_changed_device)

func _is_avalible():
	return current_multichecker!=null and current_multichecker.is_activated()

func set_multichecker(multichecker:MulticheckerV2):
	current_multichecker=multichecker
	multichecker_changed.emit(current_multichecker)
	if button_container:
		for b in button_container.get_children():
			b.queue_free()
	if multichecker:
		_build_buttons(current_multichecker.items)
		_set_prompt_desc(multichecker.prompt_desc)
		collection.hide()
		prompt.show()
		show()
	else:
		showed=false
		hide()

# Updates displayed key binding when input device changes
func _changed_device():
	_set_prompt_action()

func _set_prompt_action():
	var img_path:=IV.action_to_button_image(prompt_action)
	if ResourceLoader.exists(img_path):
		prompt_key_image.texture = load(img_path)
		prompt_key_image.show()
		prompt_label.hide()
	else:
		prompt_label.text=IV.action_to_key(prompt_action)
		prompt_label.show()
		prompt_key_image.hide()

func _set_prompt_desc(desc:String):
	prompt_desc_label.text=tr(desc)

func _build_buttons(items:Array[MulticheckerItem]):
	
	for data in items:
		
		var key:KLKey = current_multichecker.keys_root.get_node("Key_%s" % [data.name.replace(" ","_")])
		
		var btn = Button.new()
		btn.name = "Button_%s" % [data.name.replace(" ","_")]
		btn.text = tr(data.name)
		btn.custom_minimum_size.y=32
		btn.toggle_mode = data.toggled
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Connect visibility changes
		data.visible_changed.connect(func(value):btn.visible = value)
		btn.visible = data.visible
		button_container.add_child(btn)
		
		if data.toggled:
			btn.button_pressed=key.activated
		
		multichecker_changed.connect(
			func(_to):
				for s in key.get_signal_connection_list("active").filter(
					func(x:Dictionary):
						return x.callable==_on_ui_key_active):
					key.active.disconnect(s.callable)
				)
		
		key.active.connect(_on_ui_key_active)
		
		# Connect lock state to button disability
		key._lock.activated.connect(func(b): btn.disabled = b)
		
		# Handle button press - trigger key if activated
		btn.pressed.connect(func():
			if current_multichecker.is_activated():
				key.trigger()
				return
			btn.button_pressed=false)

func _on_ui_key_active(items:Array[MulticheckerItem]):
	if not current_multichecker:
		push_error("MulticheckerV2 is't exists")
		return
	
	if not current_multichecker.is_activated(): return
	
	# Manage UI visibility for multi-choice menus
	if items.size() > 1:
		collection.visible = not current_multichecker.close_after_choice
		prompt.visible = current_multichecker.close_after_choice
	
		# Auto-close behavior
		if current_multichecker.close_after_choice:
			FNC.set_pause(false)

## Finds nearest visible button to given index. Used for focus management in menu navigation
func _get_nearest_visible_button_id(id:int=0) -> int:
	var count := button_container.get_child_count()

	# Validate input and check if target button is visible
	if id < 0 or id >= count:
		return -1
	var btn_at_id := button_container.get_child(id) as Button
	if btn_at_id.visible:
		return id

	# Search in expanding radius around target index
	for step in range(1, count):
		# Check left side first
		var left_idx := id - step
		if left_idx >= 0:
			var btn_left := button_container.get_child(left_idx) as Button
			if btn_left.visible:
				return left_idx

		# Check right side
		var right_idx := id + step
		if right_idx < count:
			var btn_right := button_container.get_child(right_idx) as Button
			if btn_right.visible:
				return right_idx

	# No visible button found
	return -1

func _update_focus(current_id:int) -> void:
	if button_container and button_container.get_child_count() > 0 and collection and collection.visible:
		var nearest_button_id = _get_nearest_visible_button_id(current_id)
		if nearest_button_id >= 0:
			button_container.get_child(nearest_button_id).grab_focus()

# Controls menu visibility and pause state
func set_showed(value: bool):
	showed=value and current_multichecker!=null
	
	if is_node_ready():
		if showed:
			_update_focus(current_multichecker.current_id)
		collection.visible=showed and _is_avalible()
		if current_multichecker!=null and current_multichecker.time_stop:
			FNC.set_pause(value)
		prompt.visible=not showed
