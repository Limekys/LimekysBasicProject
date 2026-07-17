// Simple Music Player by Limekys 2026.07.17 (This script has MIT Licence)
// Dependencies: -
#macro LIME_VOLIMUSIC "2026.07.17"

/// @enum _VoliMusicState
enum _VoliMusicState {
    STOPPED,
    PLAYING,
    PAUSED
}

function VoliMusic() constructor {
    
    playlist = [];
    current_track_id = 0;
    current_track = -1;
    state = _VoliMusicState.STOPPED;
    
    shuffle_mode = false;
    shuffle_order = [];
    shuffle_index = 0;
    
    current_volume = 1;
    
    // ─── Private helpers ────────────────────────────────────────────
    
    /// @description Fisher-Yates shuffle — returns an array of indices [0..len-1] in random order
    function _generate_shuffle_order() {
        var _len = array_length(playlist);
        var _order = [];
        for (var i = 0; i < _len; i++) {
            _order[i] = i;
        }
        for (var i = _len - 1; i > 0; i--) {
            var j = irandom(i);
            var _temp = _order[i];
            _order[i] = _order[j];
            _order[j] = _temp;
        }
        return _order;
    }
    
    /// @description Resolves the actual playlist index, taking shuffle into account
    function _get_current_index() {
        if (shuffle_mode && array_length(shuffle_order) > 0) {
            return shuffle_order[shuffle_index];
        }
        return current_track_id;
    }
    
    /// @description Starts playback of the track at the current resolved index
    function _start_current() {
        if (array_length(playlist) == 0) return;
        var _idx = _get_current_index();
        current_track = audio_play_sound(playlist[_idx], 1, false, current_volume);
        state = _VoliMusicState.PLAYING;
    }
    
    // ─── Public API ─────────────────────────────────────────────────
    
    function play() {
        if (array_length(playlist) == 0) return;
        
        // Resume from pause
        if (state == _VoliMusicState.PAUSED) {
            audio_resume_sound(current_track);
            state = _VoliMusicState.PLAYING;
            return;
        }
        
        // Start from stopped
        if (state == _VoliMusicState.STOPPED) {
            _start_current();
        }
    }
    
    function pause() {
        if (state == _VoliMusicState.PLAYING) {
            audio_pause_sound(current_track);
            state = _VoliMusicState.PAUSED;
        }
    }
    
    function stop() {
        if (current_track != -1) {
            audio_stop_sound(current_track);
        }
        current_track = -1;
        state = _VoliMusicState.STOPPED;
    }
    
    /// @description Toggles shuffle mode. Rebuilds the shuffle order on enable.
    function shuffle() {
        shuffle_mode = !shuffle_mode;
        if (shuffle_mode) {
            shuffle_order = _generate_shuffle_order();
            // Jump to the position of the currently playing track in the new order
            shuffle_index = 0;
            if (array_length(playlist) > 0) {
                for (var i = 0; i < array_length(shuffle_order); i++) {
                    if (shuffle_order[i] == current_track_id) {
                        shuffle_index = i;
                        break;
                    }
                }
            }
        }
    }
    
    function next() {
        stop();
        if (array_length(playlist) == 0) return;
        
        if (shuffle_mode) {
            shuffle_index++;
            // All tracks played — generate a fresh order
            if (shuffle_index >= array_length(shuffle_order)) {
                shuffle_order = _generate_shuffle_order();
                shuffle_index = 0;
            }
        } else {
            current_track_id++;
            if (current_track_id >= array_length(playlist)) {
                current_track_id = 0;
            }
        }
        
        _start_current();
    }
    
    function previous() {
        stop();
        if (array_length(playlist) == 0) return;
        
        if (shuffle_mode) {
            shuffle_index--;
            if (shuffle_index < 0) {
                shuffle_index = array_length(shuffle_order) - 1;
            }
        } else {
            current_track_id--;
            if (current_track_id < 0) {
                current_track_id = array_length(playlist) - 1;
            }
        }
        
        _start_current();
    }
    
    function volume(_vol) {
        current_volume = clamp(_vol, 0, 1);
        if (current_track != -1 && state == _VoliMusicState.PLAYING) {
            audio_sound_gain(current_track, current_volume, 0);
        }
    }
    
    function load(_music) {
        if (!is_array(_music)) {
            _music = [_music];
        }
        playlist = array_concat(playlist, _music);
        
        // Rebuild shuffle order when playlist changes
        if (shuffle_mode) {
            shuffle_order = _generate_shuffle_order();
            shuffle_index = 0;
        }
    }
    
    /// @description Call this every step to auto-advance when a track ends
    function update() {
        if (state == _VoliMusicState.PLAYING 
            && current_track != -1 
            && !audio_is_playing(current_track)) 
        {
            next();
        }
    }
    
    function clear() {
        stop();
        playlist = [];
        current_track_id = 0;
        shuffle_order = [];
        shuffle_index = 0;
    }
    
    function print_list() {
        show_debug_message("Music list: " + string(playlist));
    }
}