class MassEncryption::BatchEncryptionJob < MassEncryption::ApplicationJob
  def perform(batch, auto_enqueue_next: true)
    if batch.present?
      batch.encrypt
      self.class.perform_later batch.next if auto_enqueue_next
    end
  end
end