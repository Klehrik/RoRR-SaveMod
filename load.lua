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
    --gm.player_set_class(player, save.class)
    director.player_level = save.level
    hud.gold = save.gold
    director.player_exp = save.exp
    director.player_exp_required = save.exp_req
    player.infusion_hp = save.infusion_hp
    gm.actor_skin_set(player, save.skin_current)
    
    -- Equipment
    local equip = Equipment.find(save.equipment)
    if equip then gm.equipment_set(player, equip) end

    -- Skills
    for i = 1, 4 do gm.actor_skill_set(player, i - 1, save.skills[i]) end

    -- Drones
    for k, v in pairs(save.drones) do
        for i = 1, v do gm.instance_create_depth(player.x, player.y, 0, gm.constants[k]) end
    end


    log.info("Loaded Slot "..slot)
end


function load_class_from_slot(slot)
    local player = Player.get_client()
    
    local save = saves[slot]

    -- Class
    local s = Instance.find(gm.constants.oSelectMenu)
    if s then gm.call(s.set_choice.script_name, s, s, save.class) end
end


function load_items_from_slot(slot)
    local player = Player.get_client()
    
    local save = saves[slot]

    -- Items
    for _, i in ipairs(save.items) do
        local item = Item.find(i[1])
        if item then
            gm.item_give(player, item, i[2], false)
            if i[3] then gm.item_give(player, item, i[3], true) end
        end
    end
end


function load_artifacts_from_slot(slot)
    local save = saves[slot]

    -- Artifacts
    for i = 1, #save.artifacts do
        gm.array_set(class_artifact[i], 8, save.artifacts[i])
    end
end


function load_game_report_from_slot(slot)
    local player = Player.get_client()
    
    local save = saves[slot]

    -- Game Report
    for k, v in pairs(save.game_report) do
        gm.struct_set(player.game_report, k, v)
    end
end