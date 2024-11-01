-- Load

function load_from_slot(slot)
    local director = Instance.find(gm.constants.oDirectorControl)
    local hud = Instance.find(gm.constants.oHUD)
    local player = Player.get_client()

    local save = saves[slot]


    -- Go to saved stage
    gm.stage_goto(gm.stage_find(save.stage))
    gm.variable_global_set("stage_current_level", save.stage_current_level)

    -- Run data
    director.stages_passed = save.stages_passed - 1
    director.time_start = save.time_start
    director.time_total = save.time_total
    hud.minute, hud.second = seconds_to_minutes(save.time_start)
    director.enemy_buff = save.enemy_buff
    gm.difficulty_set_active(gm.difficulty_find(save.difficulty))


    -- Player stats
    director.player_level = save.level
    hud.gold = save.gold
    director.player_exp = save.exp
    director.player_exp_required = save.exp_req
    player.infusion_hp = save.infusion_hp
    gm.actor_skin_set(player.value, save.skin_current)
    
    -- Equipment
    local equip = Equipment.find(save.equipment)
    if equip then player:set_equipment(equip) end

    -- Skills
    for i = 1, 4 do gm.actor_skill_set(player.value, i - 1, Skill.find(save.skills[i]).value) end

    -- Drones
    for k, v in pairs(save.drones) do
        for i = 1, v do Object.find("ror", k):create(player.x, player.y) end
    end


    log.info("Loaded Slot "..slot)
end


function load_class_from_slot(slot)    
    local save = saves[slot]

    -- Class
    local s = Instance.find(gm.constants.oSelectMenu)
    if s:exists() then gm.call(s.set_choice.script_name, s.value, s.value, save.class) end
end


function load_items_from_slot(slot)
    local player = Player.get_client()
    
    local save = saves[slot]

    -- Items
    for _, i in ipairs(save.items) do
        local item = Item.find(i[1])
        if item then
            player:item_give(item, i[2], false)
            if i[3] then player:item_give(item, i[3], true) end
        end
    end
end


function load_artifacts_from_slot(slot)
    local save = saves[slot]

    -- Artifacts
    for i = 1, #save.artifacts do
        Class.ARTIFACT:get(i - 1):set(8, save.artifacts[i])
    end
end


function load_game_report_from_slot(slot)
    local player = Player.get_client()
    
    local save = saves[slot]

    -- Game Report
    for k, v in pairs(save.game_report) do
        if k == "stages_completed" then v = v + 1 end   -- Fix off-by-one
        gm.struct_set(player.game_report, k, v)
    end
end