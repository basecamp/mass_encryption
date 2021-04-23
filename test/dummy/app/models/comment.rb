class Comment < ApplicationRecord
  has_rich_text :content, encrypted: true
end
