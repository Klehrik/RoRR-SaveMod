-- Mouse

Mouse = {}

__mouse = __mouse or {
    x = 0,  -- Screen coordinates, not world; (0, 0) is top-left of screen
    y = 0,

    x_prev = 0,
    y_prev = 0,
    x_diff = 0,
    y_diff = 0,

    left_held      = false,
    right_held     = false,
    left_pressed   = false,
    right_pressed  = false,
    left_released  = false,
    right_released = false,
}



-- ========== Methods ==========

Mouse.get = function()
    return Util.table_shallow_copy(__mouse)
end



-- ========== Hooks ==========

Hook.add_pre(gm.constants.__input_system_tick, function(self, other, result, args)
    local cam = Global.view_camera
    local cam_x, cam_y = gm.camera_get_view_x(cam), gm.camera_get_view_y(cam)

    -- Get mouse screen coordinates
    __mouse.x = Global.mouse_x - cam_x
    __mouse.y = Global.mouse_y - cam_y

    -- Calculate offset from previous position
    __mouse.x_diff = __mouse.x - __mouse.x_prev
    __mouse.y_diff = __mouse.y - __mouse.y_prev
    __mouse.x_prev = __mouse.x
    __mouse.y_prev = __mouse.y

    -- Save mouse press state into variables
    __mouse.left_held       = Util.bool(gm.mouse_check_button(1))
    __mouse.right_held      = Util.bool(gm.mouse_check_button(3))
    __mouse.left_pressed    = Util.bool(gm.mouse_check_button_pressed(1))
    __mouse.right_pressed   = Util.bool(gm.mouse_check_button_pressed(3))
    __mouse.left_released   = Util.bool(gm.mouse_check_button_released(1))
    __mouse.right_released  = Util.bool(gm.mouse_check_button_released(3))
end)