json.id time_slot.id
json.court_id time_slot.court_id
json.day_of_week time_slot.day_of_week
json.start_time time_slot.start_time.strftime("%H:%M")
json.end_time time_slot.end_time.strftime("%H:%M")
json.is_available time_slot.is_available
