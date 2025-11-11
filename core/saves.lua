-- Saves

local file = TOML.new("saves")
local read = file:read()
__saves = (read and read.saves) or {}
__current = 0


function save_to_slot(self)
    if Net.online then return end

    -- Use next slot index for new file
    if __current <= 0 then __current = #__saves + 1 end

    local hud = Instance.find(gm.constants.oHUD)
    local player = Player.get_local()

    local survivor = Survivor.wrap(player.class)
    local stage = Stage.wrap(Global.stage_id)
    local difficulty = Difficulty.wrap(Global.diff_level)

    local save = {
        survivor = {
            namespace = survivor.namespace,
            identifier = survivor.identifier,
        },
        stage = {
            namespace = stage.namespace,
            identifier = stage.identifier,
            current_level = Global.stage_current_level, -- Loops back to 1 on loop
            current_total = self.stages_passed + 2,
        },
        difficulty = {
            namespace = difficulty.namespace,
            identifier = difficulty.identifier,
        },
        artifacts = {},
        time = {
            start = self.time_start,
            total = self.time_total,
        },
        date = gm.date_current_datetime(),

        -- Other
        enemy_buff = self.enemy_buff,
        gold = hud.gold,
        level = self.player_level,
        exp = self.player_exp,
        exp_required = self.player_exp_required,
        infusion_hp = player.infusion_hp,
        skin_current = player.skin_current,
        skills = {},
        items = {},
        equipment = {},
        drones = {},
        game_report = {},
    }

    -- Artifacts
    for i = 0, Global.count_artifact - 1 do
        local artifact = Artifact.wrap(i)
        if Util.bool(artifact.active) then
            table.insert(save.artifacts, {
                namespace  = artifact.namespace,
                identifier = artifact.identifier
            })
        end
    end

    -- Skills
    for i = 1, 4 do
        local skill = Skill.wrap(player:get_default_skill(i - 1).skill_id)
        table.insert(save.skills, {
            namespace  = skill.namespace,
            identifier = skill.identifier
        })
    end

    -- Items
    local size = #player.inventory_item_order
    if size > 0 then
        for i = 1, size do
            local item = Item.wrap(player.inventory_item_order[i])
            table.insert(save.items, {
                namespace  = item.namespace,
                identifier = item.identifier,
                real       = player:item_count(item, Item.StackKind.NORMAL),
                fake       = player:item_count(item, Item.StackKind.TEMPORARY_BLUE)
            })
        end
    end

    -- Equipment
    local equipment = player:equipment_get()
    if equipment then
        save.equipment = {
            namespace  = equipment.namespace,
            identifier = equipment.identifier
        }
    end

    -- Drones
    local drones = Instance.find_all(Object.Parent.DRONE)
    local count = {}
    for _, drone in ipairs(drones) do
        local object = drone:get_object()

        -- Create tables if existn't
        count[object.namespace] = count[object.namespace] or {}
        local ns = count[object.namespace]
        ns[object.identifier] = ns[object.identifier] or 0

        -- Add 1
        ns[object.identifier] = ns[object.identifier] + 1
    end
    for namespace, namespace_t in pairs(count) do
        for identifier, count in pairs(namespace_t) do
            table.insert(save.drones, {
                namespace   = namespace,
                identifier  = identifier,
                count       = count
            })
        end
    end

    -- Game report
    for k, v in pairs(player.game_report) do
        save.game_report[k] = v
    end

    __saves[__current] = save
    file:write({saves = __saves})
end


function load_survivor_from_slot(self)
    if __current <= 0 then return end
    local save = __saves[__current]

    -- Survivor
    local survivor = Survivor.find(save.survivor.identifier, save.survivor.namespace)
    if survivor then self.set_choice(survivor) end
end


function load_artifacts_from_slot()
    if __current <= 0 then return end
    local save = __saves[__current]

    -- Artifacts
    for i = 0, Global.count_artifact - 1 do
        local artifact = Artifact.wrap(i)
        artifact.active = false
    end
    for _, artifact_t in ipairs(save.artifacts) do
        local artifact = Artifact.find(artifact_t.identifier, artifact_t.namespace)
        if artifact then artifact.active = true end
    end
end


function load_from_slot(self)
    if __current <= 0 then return end
    local save = __saves[__current]
    local hud = Instance.find(gm.constants.oHUD)
    local player = Player.get_local()

    -- Go to saved stage
    local stage = Stage.find(save.stage.identifier, save.stage.namespace)
    if stage then GM.stage_goto(stage) end

    -- Run data
    Global.stage_current_level = save.stage.current_level
    self.stages_passed = save.stage.current_total - 2
    self.time_start = save.time.start
    self.time_total = save.time.total
    hud.minute, hud.second = seconds_to_minutes(save.time.start)
    self.enemy_buff = save.enemy_buff

    -- Difficulty
    local difficulty = Difficulty.find(save.difficulty.identifier, save.difficulty.namespace)
    if difficulty then GM.difficulty_set_active(difficulty) end

    -- Player stats
    hud.gold = save.gold
    self.player_level = save.level
    self.player_exp = save.exp
    self.player_exp_required = save.exp_required
    player.infusion_hp = save.infusion_hp
    GM.actor_skin_set(player, save.skin_current)

    -- Skills
    for i, skill_t in ipairs(save.skills) do
        if skill_t then
            local skill = Skill.find(skill_t.identifier, skill_t.namespace)
            if skill then player:set_default_skill(i - 1, skill) end
        end
    end

    -- Items
    -- Need to delay a frame to prevent crash when loading certain items
    Alarm.add(1, function()
        for _, item_t in ipairs(save.items) do
            local item = Item.find(item_t.identifier, item_t.namespace)
            if item then
                if item_t.real > 0 then player:item_give(item, item_t.real) end
                if item_t.fake > 0 then player:item_give(item, item_t.temp, Item.StackKind.TEMPORARY_BLUE) end
            end
        end
    end)
    
    -- Equipment
    local equipment = Equipment.find(save.equipment.identifier, save.equipment.namespace)
    if equipment then
        player:equipment_set(equipment)
    end

    -- Drones
    for _, drone_t in pairs(save.drones) do
        local drone = Object.find(drone_t.identifier, drone_t.namespace)
        if drone then
            for i = 1, drone_t.count do
                drone:create(player.x, player.y)
            end
        end
    end

    -- Game report
    for k, v in pairs(save.game_report) do
        player.game_report[k] = v
    end
end


function delete_save()
    if __current <= 0 then return end
    table.remove(__saves, __current)
    file:write({saves = __saves})
    __current = 0
end