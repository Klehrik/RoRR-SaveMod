-- SaveMod

mods["ReturnsAPI-ReturnsAPI"].auto{
    namespace   = "saveMod",
    mp          = true
}

local fn = function()
    hotloaded = true
    require("./ui/element")
    require("./ui/queue")
    require("./ui/mouse")
    require("./core/util")
    require("./core/saves")
    require("./core/render")
end
Initialize.add(fn)
if hotloaded then fn() end



-- ========== Hooks ==========

-- Reset slot selection
Hook.add_post("gml_Object_oSelectMenu_Create_0", function(self, other)
    __current = 0
end)


-- Load survivor from slot
local run_start_hook
run_start_hook = Hook.add_post(gm.constants.__input_system_tick, function(self, other, result, args)
    -- Run this hook until oSelectMenu exists, then
    -- add a hook for `run_start` and turn off this one
    local d = Instance.find(gm.constants.oSelectMenu)
    if Instance.exists(d) then
        run_start_hook:toggle(false)
        
        Hook.add_pre(gm.constants[d.run_start.value.script_name:sub(12, -1)], function(self, other)
            load_survivor_from_slot(self)
        end)
    end
end)


-- Load artifacts from slot
Hook.add_post(gm.constants.game_lobby_apply_rules, function(self, other, result, args)
    load_artifacts_from_slot()
end)


-- Load the rest from slot
Hook.add_post("gml_Object_oDirectorControl_Other_4", function(self, other)
    if self.stages_passed > 0 then return end
    load_from_slot(self)
end)


-- Save to slot
Hook.add_post(gm.constants.stage_goto, function(self, other, result, args)
    if (not self) or (not self.stages_passed) then return end
    save_to_slot(self)
end)


-- Delete save on defeat/victory
Hook.add_post(gm.constants.actor_set_dead, function(self, other, result, args)
    if args[1].value:get_object_index() ~= gm.constants.oP then return end
    delete_save()
end)

Hook.add_post("gml_Object_oCommandFinal_Alarm_0", function(self, other)
    delete_save()
end)