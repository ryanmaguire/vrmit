# ! WIP file for getting the stream from the Meta Quest headset camera.
# So far, works to get the stream, but not implemented into anything.

# IMPORTANT: Must give custom permission `horizonos.permission.HEADSET_CAMERA` in export settings.
# Don't forget to allocate relevant android permissions as well in addition to the meta specific one.

extends Node

@export var camera_display: MeshInstance3D 

var _quest_camera_feed: CameraFeed
var camera_texture: CameraTexture

func _ready() -> void:
	print("[camera_access] Requesting permissions")
	OS.request_permissions()
	
	print("[camera_access] Detecting hardware")
	_detect_all_cameras()
	
	# Activate camera and begin monitoring for feeds
	CameraServer.set_monitoring_feeds(true)
	var feeds = CameraServer.feeds()
	
	# Handle camera settings now
	if feeds.size() > 0:
		# Typically camera index 2 is the right camera, 0 is the front IR, 1 is the left front
		_quest_camera_feed = feeds[2] # <-- This index can be adjusted based on the above cameras detected.
		print("[camera_access] Selected camera: ", _quest_camera_feed.get_name())
		
		# Display the avaliable camera formats in the console. Once again, select one.
		var available_formats = _quest_camera_feed.get_formats()
		print("[camera_access] Available formats: ", available_formats)
#		[{ "width": 320, "height": 240, "format": "YUV_420_888" }, 
		#{ "width": 640, "height": 360, "format": "YUV_420_888" }, 
		#{ "width": 640, "height": 480, "format": "YUV_420_888" }, 
		#{ "width": 720, "height": 480, "format": "YUV_420_888" }, 
		#{ "width": 854, "height": 480, "format": "YUV_420_888" }, 
		#{ "width": 800, "height": 600, "format": "YUV_420_888" }, 
		#{ "width": 1024, "height": 576, "format": "YUV_420_888" }, 
		#{ "width": 1024, "height": 768, "format": "YUV_420_888" }, 
		#{ "width": 1280, "height": 720, "format": "YUV_420_888" }, 
		#{ "width": 1280, "height": 960, "format": "YUV_420_888" }, 
		#{ "width": 1600, "height": 1200, "format": "YUV_420_888" }] 


		_quest_camera_feed.set_format(8, { "output": "separate" }) # <-- Replace first index here with selected one.
	else:
		push_error("[camera_access] No cameras detected. Did you assign the right permissions?")

func _process(_delta: float) -> void:
	# If we have the feed, but haven't set up the texture yet...
	if _quest_camera_feed and camera_texture == null:
		
		# Turn on the actual camera.
		_quest_camera_feed.set_active(true)
		
		# This check avoids a really weird bug I was experiencing when improper permissions are set.
		# In this case, the feed is active, but the actual OS doesn't recognize it as active.
		# This checks for that.
		if _quest_camera_feed.feed_is_active:
			print("[camera_access] Setting up texture")
			_setup_camera_texture()
			
			# Once the texture is setup, stop processing this node.
			set_process(false)

func _setup_camera_texture() -> void:
	var active_material = camera_display.material_override
	if active_material == null:
		push_error("[camera_access] No material found on camera mesh")
		return
	
	# EXPERIMENTAL. *Supposedly* godot can auto convert formats, but I'm not sure.
	if active_material is StandardMaterial3D:
		print("[camera_access] Using experimental StandardMaterial")
		var standard_tex = CameraTexture.new()
		standard_tex.camera_feed_id = _quest_camera_feed.get_id()
		
		active_material.albedo_texture = standard_tex
		print("[camera_access] READY: Bound to StandardMaterial")
		
	elif active_material is ShaderMaterial:
		# Brightness
		var tex_y = CameraTexture.new()
		tex_y.camera_feed_id = _quest_camera_feed.get_id()
		tex_y.which_feed = CameraServer.FEED_Y_IMAGE
		
		# Chroma
		var tex_uv = CameraTexture.new()
		tex_uv.camera_feed_id = _quest_camera_feed.get_id()
		tex_uv.which_feed = CameraServer.FEED_CBCR_IMAGE
		
		# Bind to shader
		active_material.set_shader_parameter("camera_y", tex_y)
		active_material.set_shader_parameter("camera_uv", tex_uv)
		print("[camera_access] READY: Bound Y and UV textures to Shader.")

func _detect_all_cameras() -> void:
	CameraServer.set_monitoring_feeds(true)
	
	var feeds = CameraServer.feeds()
	
	if feeds.is_empty():
		push_warning("[camera_access] Nothing detected")
		return
			
	for i in range(feeds.size()):
		var feed = feeds[i]
		var feed_name = feed.get_name()
		var feed_id = feed.get_id()
		
		print("    Index ", i, " | Name: ", feed_name, " | ID: ", feed_id)
