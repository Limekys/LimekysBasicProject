//Simple Camera Manager by Limekys (requare UsefulFunctions script)
#macro LIMEKYS_SIMPLE_CAMERA_VERSION "2022.07.23"
#macro LIME_CAMERA _LimeGetCamera()

function _LimeGetCamera() {
	static Camera = function() constructor {
		self.x = 0;
		self.y = 0;
		self.start_width = 1920;
		self.start_height = 1080;
		self.width = 1920;
		self.height = 1080;
		self.target_object = noone;
		self.target_x = 0;
		self.target_y = 0;
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
		
		self.debug_enabled = false;
		
		//Shake
		self.shake = 0;
		self.shake_length = 0;
		self.shake_length_max = 0;
		self.shake_magnitude = 0;
		
		//Zoom
		self.camera_zoom = 1.0;
		self.camera_zoom_target = 1.0;
		
		//Debug camera view sizes
		self.camera_width_offset = 1.0;
		self.camera_height_offset = 1.0;
		
		///@func Init(width, height, target_object)
		static Init = function(width, height, target_object) {
			self.start_width = width;
			self.start_height = height;
			self.width = width;
			self.height = height;
			self.width_half = floor(self.width / 2);
			self.height_half = floor(self.height / 2);
			self.target_object = target_object;
			self.camera_zoom = 1.0;
			self.camera_zoom_target = 1.0;
			
			camera_set_view_size(self.camera_view, self.width, self.height);
			view_set_wport(self.view_index, self.width);
			view_set_hport(self.view_index, self.height);
			
			return self;
		}
		
		static Update = function() {
			
			//Smoothnest zoom
			if self.camera_zoom != self.camera_zoom_target {
				self.camera_zoom = clamp(SmoothApproachDelta(self.camera_zoom, self.camera_zoom_target, 4), 0.1, 2.0);
				
				self.width = self.start_width / self.camera_zoom;
				self.height = self.start_height / self.camera_zoom;
				
				self.width_half = floor(self.width / 2);
				self.height_half = floor(self.height / 2);
				
				camera_set_view_size(self.camera_view, self.width, self.height);
				view_set_wport(self.view_index, self.width);
				view_set_hport(self.view_index, self.height);
			}
			
			//Follow target object
			if self.target_object != undefined && instance_exists(self.target_object) {
				if self.target_object.phy_active {
					self.target_x = self.target_object.phy_position_x + self.x_offset;
					self.target_y = self.target_object.phy_position_y + self.y_offset;
				} else {
					self.target_x = self.target_object.x + self.x_offset;
					self.target_y = self.target_object.y + self.y_offset;
				}
				self.x = SmoothApproachDelta(self.x, self.target_x, 8, 0);
				self.y = SmoothApproachDelta(self.y, self.target_y, 8, 0);
			}
			
			//Shaking
			if self.shake > 0 {
				self.x += random_range(-self.shake, self.shake);
				self.y += random_range(-self.shake, self.shake);
				self.shake = self.shake_magnitude * (self.shake_length / self.shake_length_max);
				self.shake_length -= DT;
			}
			
			//Update view camera
			camera_set_view_pos(self.camera_view, self.x - self.width_half, self.y - self.height_half);
			
			//Update camera vars position
			if self.debug_enabled {
				var _test_w = camera_get_view_width(self.camera_view);
				var _test_h = camera_get_view_height(self.camera_view);
				self.x1 = self.x - _test_w*0.5;
				self.y1 = self.y - _test_h*0.5;
				self.x2 = self.x1 + _test_w;
				self.y2 = self.y1 + _test_h;
			} else {
				self.x1 = self.x - self.width_half;
				self.y1 = self.y - self.height_half;
				self.x2 = self.x + self.width_half;
				self.y2 = self.y + self.height_half;
			}
			
			//Debug
			if keyboard_check_pressed(vk_numpad6) self.camera_width_offset += 0.1;
			if keyboard_check_pressed(vk_numpad4) self.camera_width_offset -= 0.1;
			if keyboard_check_pressed(vk_numpad8) self.camera_height_offset += 0.1;
			if keyboard_check_pressed(vk_numpad2) self.camera_height_offset -= 0.1;
			
			if keyboard_check_pressed(vk_pageup) self.camera_zoom_target += 0.1;
			if keyboard_check_pressed(vk_pagedown) self.camera_zoom_target -= 0.1;
		}
		
		///@func SetViewSize(scale)
		static SetViewSize = function(scale) {
			self.camera_zoom_target = scale;
			return self;
		}
		
		///@func SetPosition(x, y)
		static SetPosition = function(x, y) {
			self.x = x;
			self.y = y;
			return self;
		}
		
		///@func SetOffset(x_offset, y_offset)
		static SetOffset = function(x_offset, y_offset) {
			self.x_offset = x_offset;
			self.y_offset = y_offset;
			return self;
		}
		
		///@func Shake(magnitude,seconds)
		static Shake = function(magnitude, seconds) {
			if (magnitude > self.shake) {
				self.shake = magnitude;
				self.shake_magnitude = magnitude;
				self.shake_length = seconds;
				self.shake_length_max = seconds;
			}
			return self;
		}
	}
	static inst = new Camera();
    return inst;
}

///@func ObjectInView([offset])
function ObjectInView(offset = 32) {
	return (bbox_right+offset > LIME_CAMERA.x1
	&& bbox_left-offset < LIME_CAMERA.x2
	&& bbox_bottom+offset > LIME_CAMERA.y1
	&& bbox_top-offset < LIME_CAMERA.y2)
}

///@func CheckInView(x1, y1, x2, y2, [offset])
function CheckInView(x1, y1, x2, y2, offset = 0) {
	return (x1 - offset <= LIME_CAMERA.x2
	&& x2 + offset >= LIME_CAMERA.x1
	&& y1 - offset <= LIME_CAMERA.y2
	&& y2 + offset >= LIME_CAMERA.y1)
}