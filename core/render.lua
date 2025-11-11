-- Render

local sSave = Sprite.new("save", "~/save.png", 2, 0, 0)
Sprite.new("saveModTimer", "~/timer.png", 2)

local bg_surf

__content = Element.new(
    Global.___view_l_x2 + 4, Global.___view_l_y2 - 200,
    function(self, x, y)
        -- Set panel position
        if self.open then
             self.x = math.lerp(x, Global.___view_l_x2 - 322, 0.15)
        else self.x = math.lerp(x, Global.___view_l_x2 + 4,   0.15)
        end

        self.y = Global.___view_l_y2 - 200


        -- Gray background + border
        gm.draw_set_color(Color(0x171717))
        gm.draw_rectangle(x - 4, y - 4, x + 304, y + 104, false)

        gm.scribble_set_starting_format("fntNormal", Color.WHITE, 0)


        if __current > 0 then
            local save = __saves[__current]

            -- Draw background for stage
            if not Util.bool(gm.surface_exists(bg_surf)) then
                bg_surf = gm.surface_create(301, 101)
            end
            gm.surface_set_target(bg_surf)

            local stage = Stage.find(save.stage.identifier, save.stage.namespace)
            if type(stage) == "Stage" then
                local room_id = List.wrap(stage.room_list)[1]
                local bg_info = Global._room_custom_data[room_id].bg_info
                local layers = {}
                local i = 0
                while true do
                    -- Each background layer takes 12 elements
                    local bg_spr = bg_info:get(i * 12)          -- [0] sprite
                    local bg_depth = bg_info:get(i * 12 + 1)    -- [1] depth
                    if bg_spr then
                        table.insert(layers, {bg_spr, bg_depth})
                    else break
                    end
                    i = i + 1
                end
                table.sort(layers, function(a, b) return a[2] > b[2] end)
                for i, l in ipairs(layers) do
                    -- Offset each layer by some value to simulate parallax
                    gm.draw_sprite(l[1], 0, -32 - i * 32, -128 + i * 16)
                end
            end

            gm.surface_reset_target()
            gm.draw_surface(bg_surf, x, y)


            -- Contents
            local survivor = Survivor.find(save.survivor.identifier, save.survivor.namespace)
            if type(survivor) == "Survivor" then
                scribble_draw_with_shadow(x + 10, y + 6, "<#"..format_color_to_hex(survivor.primary_color)..">"..gm.translate(survivor.token_name).." <lt>Lv. "..math.floor(save.level))
            end
            
            if type(stage) == "Stage" then
                scribble_draw_with_shadow(x + 10, y + 24, gm.translate(stage.token_name).." <lt>(Stage "..math.floor(save.stage.current_total)..")")
            end

            local min, sec = format_time(save.time.start)
            local formatted = min..":"..sec
            gm.scribble_draw(x + 11, y + 42, "<spr saveModTimer 2>  <bl>"..formatted)
            gm.scribble_draw(x + 11, y + 43, "<spr saveModTimer 2>  <bl>"..formatted)
            gm.scribble_draw(x + 10, y + 43, "<spr saveModTimer 2>  <bl>"..formatted)
            gm.scribble_draw(x + 10, y + 42, "<spr saveModTimer 1>  <lt>"..formatted)

            local year, month, day = format_date(save.date)
            scribble_draw_with_shadow(x + 10, y + 78, "<lt>Last played: "..year.."/"..month.."/"..day)

            local difficulty = Difficulty.find(save.difficulty.identifier, save.difficulty.namespace)
            if type(difficulty) == "Difficulty" then
                local spr = difficulty.sprite_loadout_id
                local spr_x = x + 290 - gm.sprite_get_width(spr)/2
                local spr_y = y + 10  + gm.sprite_get_height(spr)/2
                gm.draw_sprite(spr, 2, spr_x, spr_y)
            end

            local artifact_count = #save.artifacts
            local spacing = 24
            local x_offset = 264 - (math.min(artifact_count - 1, 3) * spacing)
            for i = 1, math.min(artifact_count, 4) do
                local artifact_t = save.artifacts[i]
                local artifact = Artifact.find(artifact_t.identifier, artifact_t.namespace)
                if artifact and artifact.sprite_loadout_id then
                    gm.draw_sprite_ext(artifact.sprite_loadout_id, 1, x + x_offset, y + 84, 0.75, 0.75, 0, Color.WHITE, 1)
                end
                x_offset = x_offset + spacing 
            end
            if artifact_count > 4 then
                scribble_draw_with_shadow(x + 294, y + 78, "<fa_right><b>+"..(artifact_count - 4))
            end


        else
            gm.draw_set_color(Color(0x1b1b22))
            gm.draw_rectangle(x, y, x + 300, y + 100, false)
            gm.scribble_draw(x + 10, y + 6, "<w>A <y>new file <w>will be created upon\nreaching <y>Stage 2<w>.")
            gm.scribble_draw(x + 10, y + 60, "<w>Use the <y>arrows <w>on top to <y>change to\nan existing file<w>.")

        end
    end
)

local arrow_left = Element.new(
    0, -4,
    function(self, x, y)
        self.stretch = self.stretch or 1
        self.stretch = math.lerp(self.stretch, 1, 0.1)

        if self.enabled then
            local wave = math.sin(Global._current_frame/20)*2
            gm.draw_set_color(Color.WHITE)
            draw_arrow(x - wave, y, -1, self.stretch)

            -- Check for click
            local mouse = Mouse.get()
            if mouse.left_pressed and Util.bool(gm.point_in_rectangle(
                mouse.x, mouse.y,
                x - 10, y - 12, x + 10, y + 12
            )) then
                self.stretch = 2
                __current = math.max(__current - 1, 0)
            end

        else
            gm.draw_set_color(Color.DKGRAY)
            draw_arrow(x, y, -1, self.stretch)
        end
    end
)

local arrow_right = Element.new(
    0, -4,
    function(self, x, y)
        self.stretch = self.stretch or 1
        self.stretch = math.lerp(self.stretch, 1, 0.1)

        if self.enabled then
            local wave = math.sin(Global._current_frame/20)*2
            gm.draw_set_color(Color.WHITE)
            draw_arrow(x + wave, y, 1, self.stretch)

            -- Check for click
            local mouse = Mouse.get()
            if mouse.left_pressed and Util.bool(gm.point_in_rectangle(
                mouse.x, mouse.y,
                x - 10, y - 12, x + 10, y + 12
            )) then
                self.stretch = 2
                __current = math.min(__current + 1, #__saves)
            end

        else
            gm.draw_set_color(Color.DKGRAY)
            draw_arrow(x, y, 1, self.stretch)
        end
    end
)

local file_count = __content:add_child(Element.new(
    150, -13,
    function(self, x, y)
        local file      = (__current == 0 and "-") or __current
        local str       = gm.scribble_cache("<fa_center><fa_middle><fntSquareLarge>FILE <y>"..file.."<lt> /"..#__saves)
        local width     = gm.scribble_get_width(str)
        local box_left  = x - width/2
        local box_right = x + width/2
        
        -- Draw box and text
        local padding_h = 40
        gm.draw_set_color(Color(0x171717))
        gm.draw_rectangle(box_left - padding_h, y - 17, box_right + padding_h, y + 9, false)
        gm.scribble_draw(x, y, str)

        -- Set arrow positions
        local arrow_offset = 28
        arrow_left.x  = -width/2 - arrow_offset
        arrow_right.x = width/2  + arrow_offset

        -- Enable arrows if not at boundaries
        arrow_left.enabled = false
        arrow_right.enabled = false
        if __current > 0        then arrow_left.enabled  = true end
        if __current < #__saves then arrow_right.enabled = true end
    end
))
file_count:add_child(arrow_left)
file_count:add_child(arrow_right)

local button = __content:add_child(Element.new(
    -44, 65,
    function(self, x, y)
        gm.draw_set_color(Color(0x171717))
        gm.draw_rectangle(x, y, x + 39, y + 39, false)

        local img = 0

        -- Check for mouse over
        local mouse = Mouse.get()
        if Util.bool(gm.point_in_rectangle(
            mouse.x, mouse.y,
            x + 2, y + 2, x + 37, y + 37
        )) then
            img = 1
            if mouse.left_pressed then
                __content.open = not __content.open
            end
        end

        GM.draw_sprite_ext(sSave, img, x + 4, y + 4, 2, 2, 0, Color.WHITE, 1)
    end
))



local queue = Queue.new()

Hook.add_post(gm.constants.ui_draw_header_menu_tabs, function(self, other, result, args)
    if not Instance.exists(gm.constants.oSelectMenu) then return end
    if Net.online then return end

    queue:add_recursive(__content)
    queue:draw()
end)