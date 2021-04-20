class MassEncryption::Encryptor
  DEFAULT_BATCH_SIZE = 1000

  def initialize(only: all_encryptable_classes, except: [], batch_size: DEFAULT_BATCH_SIZE)
    only = Array(only)
    except = Array(except)

    @encryptable_classes = only - except
    @batch_size = batch_size
  end

  def encrypt_all_later
    encryptable_classes.each { enqueue_encryption_jobs_for(_1) }
  end

  private
    attr_reader :encryptable_classes, :batch_size

    def enqueue_encryption_jobs_for(encryptable_class)
      encryptable_class.all.in_batches(of: batch_size) do |records|
        MassEncryption::BatchEncryptionJob.perform_later(klass: encryptable_class, from_id: records.first.id, to_id: records.last.id)
      end
    end

    def all_encryptable_classes
      @all_encryptable_classes ||= ActiveRecord::Base.descendants.find_all { |klass| klass.encrypted_attributes.present? }
    end
end

