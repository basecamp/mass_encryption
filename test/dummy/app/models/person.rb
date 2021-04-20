class Person < ApplicationRecord
  encrypts :name
  encrypts :email, deterministic: true, downcase: true
end
