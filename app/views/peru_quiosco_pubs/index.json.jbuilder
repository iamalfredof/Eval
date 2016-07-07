json.array!(@pubs) do |pub|
  json.extract! pub, :id, :pq_firstpage_id, :pub_size, :product, :title
end