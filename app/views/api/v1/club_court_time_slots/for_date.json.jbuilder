json.date @schedule_date.iso8601
json.day_of_week @day_of_week
json.customized @customized
json.time_slots @time_slots do |time_slot|
  json.partial! "api/v1/time_slots/time_slot", time_slot: time_slot
end
