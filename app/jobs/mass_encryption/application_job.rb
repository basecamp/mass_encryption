module MassEncryption
  class ApplicationJob < ActiveJob::Base
    queue_as :encryption
  end
end
