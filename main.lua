-- Save Files v1.0.0
-- Klehrik

log.info("Successfully loaded ".._ENV["!guid"]..".")
mods.on_all_mods_loaded(function() for k, v in pairs(mods) do if type(v) == "table" and v.hfuncs then Helper = v end end end)

local saves = {}

local file_path = path.combine(paths.plugins_data(), _ENV["!guid"]..".txt")
local success, file = pcall(toml.decodeFromFile, file_path)
if success then
    saves = file.saves
end

local ready = false
local in_run = false
local current_file = 0      -- 0 is New File
local current_stage = nil
local stage_roll_value = 0
local loaded = false

local months = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}
local artifact_count = 14   -- Why is the array 189 long lmao??



-- ========== Functions ==========

-- TODO:
-- Save damage dealt and taken sliders

function save_to_slot(slot)
    local director = Helper.find_active_instance(gm.constants.oDirectorControl)
    local hud = Helper.find_active_instance(gm.constants.oHUD)
    local player = Helper.get_client_player()

    local survivor = gm.variable_global_get("class_survivor")[player.class + 1]
    local difficulty = gm.variable_global_get("class_difficulty")[gm.variable_global_get("diff_level") + 1]
    local artifact = gm.variable_global_get("class_artifact")

    local save = {
        char_str = survivor[3],
        diff_str = difficulty[3],
        date = gm.date_current_datetime(),
        stages_passed = director.stages_passed + 1,     -- Doesn't yet increment at the time of saving this
        
        stage = current_stage,
        stage_roll_value = stage_roll_value,
        time_start = director.time_start,
        time_total = director.time_total,
        difficulty = difficulty[1].."-"..difficulty[2],
        artifacts = {},

        class = player.class,
        level = director.player_level,
        exp = director.player_exp,
        exp_req = director.player_exp_required,
        gold = hud.gold,
        skills = {
            player.skills[1].active_skill.skill_id,
            player.skills[2].active_skill.skill_id,
            player.skills[3].active_skill.skill_id,
            player.skills[4].active_skill.skill_id
        },
        items = {},

        game_report = {},
    }

    for i = 1, artifact_count do
        table.insert(save.artifacts, artifact[i][9])
    end

    local items = Helper.get_all_items()
    for _, i in ipairs(items) do
        local internal = i.namespace.."-"..i.identifier
        if gm.item_find(internal) then
            save.items[internal] = gm.item_count(player, gm.item_find(internal), false)
        end
    end

    local names = gm.struct_get_names(player.game_report)
    for _, n in ipairs(names) do
        save.game_report[n] = gm.struct_get(player.game_report, n)
    end

    saves[slot] = save
    pcall(toml.encodeToFile, {saves = saves}, {file = file_path, overwrite = true})
end


function load_from_slot(slot)
    local director = Helper.find_active_instance(gm.constants.oDirectorControl)
    local hud = Helper.find_active_instance(gm.constants.oHUD)
    local player = Helper.get_client_player()

    local artifact = gm.variable_global_get("class_artifact")

    local save = saves[slot]

    -- Load file data
    gm.stage_goto(gm.stage_find(save.stage))    -- Adds 1 to stages_passed, which is decremented 3 lines below
    stage_roll_value = save.stage_roll_value

    director.stages_passed = save.stages_passed - 1
    director.time_start = save.time_start
    director.time_total = save.time_total
    hud.minute, hud.second = to_minutes(save.time_start)
    gm.difficulty_set_active(gm.difficulty_find(save.difficulty))

    for i = 1, #save.artifacts do
        artifact[i][9] = save.artifacts[i]
    end

    gm.player_set_class(player, save.class)
    director.player_level = save.level
    director.player_exp = save.exp
    director.player_exp_required = save.exp_req
    hud.gold = save.gold

    for i = 1, 4 do gm.actor_skill_set(player, i - 1, save.skills[i]) end

    local items = Helper.get_all_items()
    for _, i in ipairs(items) do
        local internal = i.namespace.."-"..i.identifier
        if save.items[internal] then
            gm.item_give(player, gm.item_find(internal), save.items[internal], false)
        end
    end

    for k, v in pairs(save.game_report) do
        gm.struct_set(player.game_report, k, v)
    end
end


function delete_save_slot(slot)
    table.remove(saves, slot)
    current_file = 0
    pcall(toml.encodeToFile, {saves = saves}, {file = file_path, overwrite = true})
end


function to_minutes(seconds)
    return math.floor(seconds / 60), math.floor(seconds % 60)
end


function get_name(local_str)
    -- Accounts for stuff that doesn't use localization strings
    local lang_map = gm.variable_global_get("_language_map")
    local l = gm.ds_map_find_value(lang_map, local_str)
    if l then return l end
    return local_str
end



-- ========== Main ==========

gui.add_imgui(function()
    if ready and not in_run and ImGui.Begin("Save Mod") then
        -- New file
        local c = current_file == 0 and "O" or "  "
        if ImGui.Button("("..c..")  NEW FILE") then
            current_file = 0
        end

        -- Saved files
        for i, s in ipairs(saves) do

            -- Only show the save if the difficulty/other custom content actually exists
            if gm.difficulty_find(s.difficulty) then
                local min, sec = to_minutes(s.time_start)
                if min < 10 then min = "0"..min end
                if sec < 10 then sec = "0"..sec end

                local date = months[gm.date_get_month(s.date)].." "..math.floor(gm.date_get_day(s.date))..", "..math.floor(gm.date_get_year(s.date))

                local c = current_file == i and "O" or "  "
                if ImGui.Button("("..c..")  "..get_name(s.char_str).."  |  "..get_name(s.diff_str)..", "..min..":"..sec..", Stage "..math.floor(s.stages_passed + 1).."  |  "..date) then
                    current_file = i
                end
            end
        end
    end

    ImGui.End()
end)


gm.pre_script_hook(gm.constants.__input_system_tick, function()
    ready = true
    local player = Helper.get_client_player()

    -- Load save slot once everything is ready
    if in_run and (not loaded) then
        if player then
            loaded = true
            if current_file > 0 then load_from_slot(current_file) end
        end
    end

    -- Delete save slot immediately on death
    -- and also upon leaving the planet
    local cmdFinal = Helper.find_active_instance(gm.constants.oCommandFinal)
    if player and player.dead and current_file > 0 then delete_save_slot(current_file) end
    if cmdFinal and cmdFinal.active > 0 then delete_save_slot(current_file) end
end)


gm.pre_script_hook(gm.constants.stage_roll_next, function(self, other, result, args)
    -- Overwrite next stage value
    stage_roll_value = stage_roll_value + 1
    if stage_roll_value > 5 then stage_roll_value = 1 end
    if args[1].value < 6.0 then args[1].value = stage_roll_value end
end)


gm.post_script_hook(gm.constants.stage_roll_next, function(self, other, result, args)
    if self.object_index ~= gm.constants.oSelectMenu then
        -- Get the identifier of the current stage
        local stage = gm.variable_global_get("class_stage")[result.value + 1]
        current_stage = stage[1].."-"..stage[2]

        -- Create new save file
        if current_file == 0 then
            table.insert(saves, {})
            current_file = #saves
        end

        -- Overwrite current save slot
        save_to_slot(current_file)
    end
end)


gm.pre_script_hook(gm.constants.run_create, function()
    in_run = true
    loaded = false
    stage_roll_value = 0
end)


gm.pre_script_hook(gm.constants.run_destroy, function()
    in_run = false
    current_file = 0
end)