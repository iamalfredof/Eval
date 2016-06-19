json.array!(@posts) do |post|
  json.extract! post, :id, :hn_id, :title, :url
end