json.id review.id
json.stars review.stars
json.comment review.comment
json.level_rating review.level_rating
json.level_category_label User.category_label(review.level_rating)
json.created_at review.created_at.iso8601
json.reviewer do
  json.id review.reviewer.id
  json.name review.reviewer.name
end
