class MassEncryption::EncryptionJobsEnqueuerJob < ActiveJob::Base
  def perform(klass:, batch_size: 1000)
    klass.all.in_batches(of: batch_size) do |records|
      MassEncryption::BatchEncryptionJob.perform_later(klass: klass, from_id: records.first.id, to_id: records.last.id)
    end
  end
end