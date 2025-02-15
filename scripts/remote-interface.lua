local function remote_interface_assign_waypoints(spidertron, waypoints)
  for _, waypoint in pairs(waypoints) do
    on_patrol_command_issued(spidertron, waypoint.position)
  end
end

local on_spidertron_given_new_destination = script.generate_event_name()
remote.add_interface("SpidertronPatrols", {
  get_events = function() return {on_spidertron_given_new_destination = on_spidertron_given_new_destination} end,
  clear_waypoints = function(unit_number) clear_spidertron_waypoints(nil, unit_number) end,
  add_waypoints = function(spidertron, waypoints) remote_interface_assign_waypoints(spidertron, waypoints) end,
})

local function spidertron_replaced(event)
  -- Called in response to Spidertron Weapon Switcher or Spidertron Enhancements event
  local previous_unit_number = event.old_spidertron.unit_number
  local spidertron = event.new_spidertron
  if global.spidertron_waypoints[previous_unit_number] then
    global.spidertron_waypoints[spidertron.unit_number] = global.spidertron_waypoints[previous_unit_number]
    global.spidertron_waypoints[spidertron.unit_number].spidertron = spidertron
    global.spidertron_waypoints[previous_unit_number] = nil
  end

  for player_index, path_render_info in pairs(global.path_renders) do
    if path_render_info[previous_unit_number] then
      path_render_info[spidertron.unit_number] = path_render_info[previous_unit_number]
      path_render_info[previous_unit_number] = nil
    end
  end
  update_spidertron_render_paths(spidertron.unit_number)

  if global.spidertrons_docked[previous_unit_number] then
    local dock_unit_number = global.spidertrons_docked[previous_unit_number]
    global.spidertrons_docked[spidertron.unit_number] = dock_unit_number
    global.spidertrons_docked[previous_unit_number] = nil
    dock_data = global.spidertron_docks[dock_unit_number]
    if dock_data then
      local connected_spidertron = dock_data.connected_spidertron
      if connected_spidertron then
        global.spidertron_docks[dock_unit_number].connected_spidertron = spidertron
      end
    end
  end

  script.register_on_entity_destroyed(spidertron)
end

local function connect_to_remote_interfaces()
  if remote.interfaces["SpidertronWeaponSwitcher"] then
    local on_spidertron_switched = remote.call("SpidertronWeaponSwitcher", "get_events").on_spidertron_switched
    script.on_event(on_spidertron_switched, spidertron_replaced)
  end
  if remote.interfaces["SpidertronEnhancements"] then
    local events = remote.call("SpidertronEnhancements", "get_events")
    local on_spidertron_replaced = events.on_spidertron_replaced
    script.on_event(on_spidertron_replaced, spidertron_replaced)

    local on_player_disconnected_spider_remote = events.on_player_disconnected_spider_remote
    if on_player_disconnected_spider_remote then
      script.on_event(on_player_disconnected_spider_remote, function(event) update_player_render_paths(game.get_player(event.player_index)) end)
    end
  end
end
script.on_load(connect_to_remote_interfaces)


return {on_spidertron_given_new_destination = on_spidertron_given_new_destination, connect_to_remote_interfaces = connect_to_remote_interfaces}