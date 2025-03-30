//Simple Camera Manager by Limekys (This script has MIT Licence)
//Dependencies: LimekysUsefulFunctions, LimekysResolutionManager
#macro LIME_CAMERA_MANAGER_VERSION "2025.03.08"
#macro LIME_CAMERA getLimeCamera()

function getLimeCamera() {
	static LimeCamera = function() constructor {
		self.x = 0;
		self.y = 0;
		self.width = 1920;
		self.height = 1080;
		self.target_object = noone;
		self.x_offset = 0;
		self.y_offset = 0;
		self.width_half = floor(self.width / 2);
		self.height_half = floor(self.height / 2);
		self.x1 = self.x - self.width_half;
		self.y1 = self.y - self.height_half;
		self.x2 = self.x + self.width_half;
		self.y2 = self.y + self.height_half;
		self.view_index = 0;
		self.camera_view = view_camera[self.view_index];
		self.smoothness = 0.1;
		self.max_distance = 512;
		
		self.debug_enabled = false;
		
		// Shake
		self.shake = 0;
		self.shake_length = 0;
		self.shake_length_max = 0;
		self.shake_magnitude = 0;
		
		// Zoom
		self.camera_zoom = 1.0;
		self.camera_zoom_target = 1.0;
		self.camera_zoom_max = 2.0;
		self.camera_zoom_min = 0.1;
		self.camera_zoom_smoothness = 0.1;
		
		// Angle
		self.camera_angle = 0;
		self.camera_angle_target = 0;
		self.camera_angle_smoothness = 0.1;
		
		// Debug camera view sizes
		self.camera_width_offset = 1.0;
		self.camera_height_offset = 1.0;
		
		// Last window sizes
		self.last_window_width = window_get_width();
		self.last_window_height = window_get_height();
		
		///@desc Initialize camera settings
		static init = function(target_object = undefined) {
			self.x_offset = 0;
			self.y_offset = 0;
			self.target_object = target_object;
			self.camera_zoom = 1.0;
			self.camera_zoom_target = 1.0;
			self.shake = 0;
			self.camera_angle = 0;
			self.camera_angle_target = 0;
			
			updateViewSize();
			
			return self;
		}
		
		//@desc Update camera view size based on screen resolution
		static updateViewSize = function() {
			var render_width = LIME_RESOLUTION.getScreenWidth();
			var render_height = LIME_RESOLUTION.getScreenHeight();

			if (render_width <= 0 || render_height <= 0) return;

			self.width = render_width / self.camera_zoom;
			self.height = render_height / self.camera_zoom;
			self.width_half = floor(self.width / 2);
			self.height_half = floor(self.height / 2);
			camera_set_view_size(self.camera_view, self.width, self.height);
			
			self.last_window_width = window_get_width();
			self.last_window_height = window_get_height();
		}
		
		///@desc Update camera
		static update = function() {
			// Check if window size changed or zoom changed
			if (self.last_window_width != window_get_width() || 
				self.last_window_height != window_get_height() || 
				self.camera_zoom != self.camera_zoom_target) {
				
				// Smooth zoom
				if self.camera_zoom != self.camera_zoom_target {
					if self.camera_zoom_smoothness == 0 {
						self.camera_zoom = clamp(self.camera_zoom_target, self.camera_zoom_max, self.camera_zoom_min);
					} else {
						self.camera_zoom = clamp(SmoothApproachDelta(self.camera_zoom, self.camera_zoom_target, self.camera_zoom_smoothness, 0.0001), self.camera_zoom_min, self.camera_zoom_max);
					}
				}
				
				updateViewSize();
			}
			
			// Smooth angle
			if self.camera_angle != self.camera_angle_target {
				if self.camera_angle_smoothness == 0 {
					self.camera_angle = self.camera_angle_target;
				} else {
					self.camera_angle = SmoothApproachDelta(self.camera_angle, self.camera_angle_target, self.camera_angle_smoothness, 0.0001);
				}
				camera_set_view_angle(self.camera_view, self.camera_angle);
			}
			
			// Follow target object
			if self.target_object != undefined && instance_exists(self.target_object) {
				if self.smoothness == 0 {
					self.x = self.target_object.x;
					self.y = self.target_object.y;
				} else {
					self.x = SmoothApproachDelta(self.x, self.target_object.x, self.smoothness, 0);
					self.y = SmoothApproachDelta(self.y, self.target_object.y, self.smoothness, 0);
				}
				// Clamp max distance from target object
				if point_distance(self.x, self.y, self.target_object.x, self.target_object.y) > self.max_distance {
					var _dir = point_direction(self.target_object.x, self.target_object.y, self.x, self.y);
					self.x = self.target_object.x + lengthdir_x(self.max_distance, _dir);
					self.y = self.target_object.y + lengthdir_y(self.max_distance, _dir);
				}
				// Offset
				self.x += self.x_offset;
				self.y += self.y_offset;
			}
			
			// Shaking
			if self.shake > 0 {
				self.x += random_range(-self.shake, self.shake);
				self.y += random_range(-self.shake, self.shake);
				self.shake = self.shake_magnitude * (self.shake_length / self.shake_length_max);
				self.shake_length -= DT;
			}
			
			// Update view camera position
			camera_set_view_pos(self.camera_view, self.x - self.width_half, self.y - self.height_half);
			
			// Update camera vars position
			self.x1 = self.x - self.width_half;
			self.y1 = self.y - self.height_half;
			self.x2 = self.x + self.width_half;
			self.y2 = self.y + self.height_half;
			
			// Debug //???//
			if self.debug_enabled {
				var _test_w = camera_get_view_width(self.camera_view);
				var _test_h = camera_get_view_height(self.camera_view);
				self.x1 = self.x - _test_w * 0.5;
				self.y1 = self.y - _test_h * 0.5;
				self.x2 = self.x1 + _test_w;
				self.y2 = self.y1 + _test_h;
				
				//if keyboard_check_pressed(vk_numpad6) self.camera_width_offset += 0.1;
				//if keyboard_check_pressed(vk_numpad4) self.camera_width_offset -= 0.1;
				//if keyboard_check_pressed(vk_numpad8) self.camera_height_offset += 0.1;
				//if keyboard_check_pressed(vk_numpad2) self.camera_height_offset -= 0.1;
			}
		}
		
		///@desc Draw camera borders
		static drawDebug = function() {
			draw_rectangle(self.x1, self.y1, self.x2, self.y2, true);
		}
		
		///@desc Set zoom scale
		static setViewSize = function(scale) {
			self.camera_zoom_target = clamp(scale, self.camera_zoom_min, self.camera_zoom_max);
			return self;
		}
		
		///@desc Get zoom scale
		static getViewSize = function() {
			return self.camera_zoom;
		}
		
		///@desc Zoom in view camera
		static zoomIn = function(amount = 0.1) {
			self.setViewSize(self.camera_zoom_target + amount);
		}
		
		///@desc Zoom out view camera
		static zoomOut = function(amount = 0.1) {
			self.setViewSize(self.camera_zoom_target - amount);
		}
		
		///@desc Set x,y position of the view camera
		static setPosition = function(x, y) {
			self.x = x;
			self.y = y;
			return self;
		}
		
		///@desc Set target object
		static setTarget = function(target_object) {
			self.target_object = target_object;
			return self;
		}
		
		///@desc Sets the camera position offset
		static setOffset = function(x_offset, y_offset) {
			self.x_offset = x_offset;
			self.y_offset = y_offset;
			return self;
		}
		
		///@desc Shake camera with magnitude power in n seconds
		static applyShake = function(magnitude, seconds) {
			if (magnitude > self.shake) {
				self.shake = magnitude;
				self.shake_magnitude = magnitude;
				self.shake_length = seconds;
				self.shake_length_max = seconds;
			}
			return self;
		}
		
		///@desc Sets the camera smoothing value when moving
		///The default setting is 0.1. Higher = Smoother. 0 = disable
		static setSmoothness = function(value = 0.1) {
			self.smoothness = value;
			return self;
		}
		
		///@desc Sets the camera smoothing value when zooming
		///The default setting is 0.1. Higher = Smoother. 0 = disable
		static setZoomSmoothness = function(value = 0.1) {
			self.camera_zoom_smoothness = value;
			return self;
		}
		
		///@desc Sets the maximum distance of the camera from the target object
		static setMaxDistance = function(value = 512) {
			self.max_distance = value;
			return self;
		}
		
		///@desc Sets camera angle
		static setAngle = function(_angle) {
			self.camera_angle_target = _angle;
			return self;
		}
		
		///@desc Sets camera angle smoothness
		///The default setting is 0.1. Higher = Smoother. 0 = disable
		static setAngleSmoothness = function(value = 0.1) {
			self.camera_angle_smoothness = value;
			return self;
		}
		
		///@desc Toggle debug mode
		static toggleDebugMode = function(_enable = -1) {
			if _enable == -1 {
				self.debug_enabled = !self.debug_enabled;
			} else {
				self.debug_enabled = _enable;
			}
		}
	}
	static inst = new LimeCamera();
	return inst;
}

///@func ObjectInView([offset])
function ObjectInView(offset = 32) { //???// Переименовать метод
	return (bbox_right+offset > LIME_CAMERA.x1
	&& bbox_left-offset < LIME_CAMERA.x2
	&& bbox_bottom+offset > LIME_CAMERA.y1
	&& bbox_top-offset < LIME_CAMERA.y2)
}

///@func CheckInView(x1, y1, x2, y2, [offset])
function CheckInView(x1, y1, x2, y2, offset = 0) { //???// Переименовать метод
	return (x2 + offset > LIME_CAMERA.x1
	&& x1 - offset < LIME_CAMERA.x2
	&& y2 + offset > LIME_CAMERA.y1
	&& y1 - offset < LIME_CAMERA.y2)
}
