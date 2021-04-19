module MassEncryption::BatchEncryptionJob
  def perform(klass:, from_id:, to_id:)
    MassEncryption::Batch.new(klass: klass, from_id: from_id, to_id: to_id).encrypt
  end
end