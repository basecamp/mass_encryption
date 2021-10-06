class MassEncryption::BatchEncryptionJob < MassEncryption::ApplicationJob
  def perform(batch, auto_enqueue_next: true)
    if batch.present?
      batch.encrypt_now
      self.class.perform_later batch.next if auto_enqueue_next
    end
  end

  ActiveSupport.run_load_hooks(:mass_encryption_batch_job, self)
end
