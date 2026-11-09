json.addresses @addresses do |address|
  json.partial! "api/v1/addresses/address", address: address
end
