Account.find_or_create_by!(tenant_id: "default", mode: "paper") do |a|
  a.name = "Default Paper Account"
  a.currency = "INR"
  a.starting_balance = 1_000_000
end
puts "Seeded default account"