-- SaveMod v1.0.2
-- Klehrik

log.info("Successfully loaded ".._ENV["!guid"]..".")
mods.on_all_mods_loaded(function() for k, v in pairs(mods) do if type(v) == "table" and v.hfuncs then Helper = v end end end)

local saves = {}

local file_path = path.combine(paths.plugins_data(), _ENV["!guid"].."-2.txt")
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

local selectMenuHook = false



-- ========== Functions ==========

function save_to_slot(slot)
    local director = Helper.find_active_instance(gm.constants.oDirectorControl)
    local hud = Helper.find_active_instance(gm.constants.oHUD)
    local player = Helper.get_client_player()

    local class_survivor = gm.variable_global_get("class_survivor")[player.class + 1]
    local class_difficulty = gm.variable_global_get("class_difficulty")[gm.variable_global_get("diff_level") + 1]
    local class_artifact = gm.variable_global_get("class_artifact")
    local class_item = gm.variable_global_get("class_item")
    local class_equipment = gm.variable_global_get("class_equipment")

    local save = {
        char_str = class_survivor[3],
        diff_str = class_difficulty[3],
        date = gm.date_current_datetime(),
        stages_passed = director.stages_passed + 1,     -- Doesn't yet increment at the time of saving this
        
        stage = current_stage,
        stage_roll_value = stage_roll_value,
        time_start = director.time_start,
        time_total = director.time_total,
        enemy_buff = director.enemy_buff,
        difficulty = class_difficulty[1].."-"..class_difficulty[2],
        artifacts = {},

        class = player.class,
        level = director.player_level,
        gold = hud.gold,
        exp = director.player_exp,
        exp_req = director.player_exp_required,
        infusion_hp = player.infusion_hp,
        equipment = "",
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
        table.insert(save.artifacts, class_artifact[i][9])
    end

    local equip = class_equipment[gm.equipment_get(player) + 1]
    save.equipment = equip[1].."-"..equip[2]

    for _, i in ipairs(player.inventory_item_order) do
        local item = class_item[i + 1]
        local internal = item[1].."-"..item[2]
        if gm.item_find(internal) then
            table.insert(save.items, {internal, gm.item_count(player, gm.item_find(internal), false)})
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

    local save = saves[slot]

    -- Load file data
    gm.stage_goto(gm.stage_find(save.stage))    -- Adds 1 to stages_passed, which is decremented 3 lines below
    stage_roll_value = save.stage_roll_value

    director.stages_passed = save.stages_passed - 1
    director.time_start = save.time_start
    director.time_total = save.time_total
    hud.minute, hud.second = to_minutes(save.time_start)
    director.enemy_buff = save.enemy_buff
    gm.difficulty_set_active(gm.difficulty_find(save.difficulty))

    gm.player_set_class(player, save.class)
    director.player_level = save.level
    hud.gold = save.gold
    director.player_exp = save.exp
    director.player_exp_required = save.exp_req
    player.infusion_hp = save.infusion_hp
    
    local equip = gm.equipment_find(save.equipment)
    if equip then gm.equipment_set(player, equip) end

    for i = 1, 4 do gm.actor_skill_set(player, i - 1, save.skills[i]) end

    for k, v in pairs(save.items) do
        local item = gm.item_find(v[1])
        if item then gm.item_give(player, item, v[2], false) end
    end

    for k, v in pairs(save.game_report) do
        gm.struct_set(player.game_report, k, v)
    end
end


function load_artifacts_from_slot(slot)
    local class_artifact = gm.variable_global_get("class_artifact")

    local save = saves[slot]

    -- Load artifact data
    for i = 1, #save.artifacts do
        gm.array_set(class_artifact[i], 8, save.artifacts[i])
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
        ImGui.Text("Select a file and enter a run to load it.\nSelecting NEW FILE will save to a new slot.\nThis panel will be hidden in-run.")

        -- New file
        local c = current_file == 0 and "O" or "  "
        if ImGui.Button("("..c..")  NEW FILE") then
            current_file = 0
        end

        -- Saved files
        for i, s in ipairs(saves) do

            -- Only show the save if the difficulty actually exists
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

    -- Enable/disable artifacts before run start
    if not selectMenuHook then
        local sMenu = Helper.find_active_instance(gm.constants.oSelectMenu)
        if sMenu then
            selectMenuHook = true
            gm.post_script_hook(gm.method_get_index(sMenu.run_start), function(self, other, result, args)
                if current_file > 0 then load_artifacts_from_slot(current_file) end
            end)
        end
    end

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