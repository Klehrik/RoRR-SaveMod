-- SaveMod
-- Klehrik

log.info("Successfully loaded ".._ENV["!guid"]..".")
mods["RoRRModdingToolkit-RoRR_Modding_Toolkit"].auto()

require("./save")
require("./load")
require("./helper")

local months = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}

saves = {}
current_file = 0

-- Load data from .txt
file_path = path.combine(paths.plugins_data(), _ENV["!guid"].."-2.txt")
local success, file = pcall(toml.decodeFromFile, file_path)
if success then saves = file.saves end

local game_loaded = false
local in_run = false
local file_loaded = 0

current_stage = nil



-- ========== Main ==========

gui.add_imgui(function()
    if game_loaded and (not in_run) and Net.get_type() == Net.TYPE.single
    and ImGui.Begin("Save Mod") then
        -- Minimum size 600x400
        local size_x, size_y = ImGui.GetWindowSize()
        size_x = math.max(size_x, 600)
        size_y = math.max(size_y, 400)
        ImGui.SetWindowSize(size_x, size_y)
        
        ImGui.Text("Select a file and enter a run to load it.\nSelecting NEW FILE will save to a new slot.\nThis panel will be hidden in-run.")

        -- New file
        local value, pressed = ImGui.RadioButton("NEW FILE", current_file, 0)
        if pressed then current_file = value end

        -- Saved files
        for i, save in ipairs(saves) do

            -- Only show the save if the difficulty actually exists
            if Difficulty.find(save.difficulty) then
                local min, sec = seconds_to_minutes(save.time_start)
                if min < 10 then min = "0"..min end
                if sec < 10 then sec = "0"..sec end

                local date = months[gm.date_get_month(save.date)].." "..math.floor(gm.date_get_day(save.date))..", "..math.floor(gm.date_get_year(save.date))

                local value, pressed = ImGui.RadioButton("[FILE "..i.."]  "..Language.translate_token(save.char_str).."  |  "..Language.translate_token(save.diff_str)..", "..min..":"..sec..", Stage "..math.floor(save.stages_passed + 1).."  |  "..date, current_file, i)
                if pressed then current_file = value end
            end
        end
    end

    ImGui.End()
end)


gm.pre_script_hook(gm.constants.__input_system_tick, function(self, other, result, args)
    game_loaded = true

    local player = Player.get_client()

    -- Load file when run is loaded
    if in_run and file_loaded < 2 and player:exists() then

        if file_loaded == 0 then
            file_loaded = 1
            if current_file > 0 then load_from_slot(current_file) end
        
        else
            file_loaded = 2
            if current_file > 0 then
                load_items_from_slot(current_file)
                load_game_report_from_slot(current_file)
            end

        end
    end

    -- Delete save slot immediately on death
    -- and also upon leaving the planet
    if in_run then
        local cmdFinal = Instance.find(gm.constants.oCommandFinal)
        if player:exists() and player.dead then delete_save_slot(current_file) end
        if cmdFinal:exists() and cmdFinal.active > 0 then delete_save_slot(current_file) end
    end
end)


gm.post_script_hook(106241.0, function(self, other, result, args)
    -- Load saved class and artifacts
    if current_file > 0 then
        load_artifacts_from_slot(current_file)
        load_class_from_slot(current_file)
    end
end)


gm.post_script_hook(gm.constants.stage_roll_next, function(self, other, result, args)
    if self.object_index ~= gm.constants.oSelectMenu then
        local director = Instance.find(gm.constants.oDirectorControl)
        if director and director.time_total > 3.0 then
            -- Get the identifier of the current stage
            local stage = Class.STAGE:get(result.value)
            current_stage = stage:get(0).."-"..stage:get(1)

            -- Create new save file
            if current_file == 0 then
                table.insert(saves, {})
                current_file = #saves
            end

            -- Overwrite current save slot
            save_to_slot(current_file)
        end
    end
end)


gm.pre_script_hook(gm.constants.run_create, function(self, other, result, args)
    in_run = true
    file_loaded = 0
end)


gm.pre_script_hook(gm.constants.run_destroy, function(self, other, result, args)
    in_run = false
    current_file = 0
end)