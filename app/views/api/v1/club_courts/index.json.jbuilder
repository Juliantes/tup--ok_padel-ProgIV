json.courts @courts do |court|
  json.partial! "api/v1/courts/court", court: court
end
