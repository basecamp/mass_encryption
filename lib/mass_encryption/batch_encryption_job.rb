class MassEncryption::BatchEncryptionJob < ActiveJob::Base
  def perform(batch)
    if batch.present?
      batch.encrypt
      self.class.perform_later batch.next
    end
  end
end