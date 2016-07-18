json.array!(@posts) do |post|
  json.extract! post, :id, :post_id, :keyword, :url
end