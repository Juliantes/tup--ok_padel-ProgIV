json.time_slot do
  json.partial! "api/v1/time_slots/time_slot", time_slot: @time_slot
end
