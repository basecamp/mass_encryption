Rails.application.routes.draw do
  mount MassEncryption::Engine => "/mass_encryption"
end
