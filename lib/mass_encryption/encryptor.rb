class MassEncryption::Encryptor
  def initialize(only: all_encryptable_classes, except: [], batch_size: 1000)
    @encryptable_classes = only - except
    @batch_size = batch_size
  end

  def enqueue_encryption_jobs
    encryptable_classes.each { enqueue_encryption_jobs_for(_1) }
  end

  private
    def enqueue_encryption_jobs_for(encryptable_class)
      encryptable_class.all.in_batches(of: batch_size) do |records|
        MassEncryption::BatchEncryptionJob.perform_later(klass: encryptable_class, from_id: records.first.id, to_id: records.last.id)
      end
    end

    attr_reader :encryptable_classes, :batch_size

    def all_encryptable_classes
      @all_encryptable_classes ||= ActiveRecord::Base.descendants.find_all { |klass| klass.encrypted_attributes.present? }
    end
end

