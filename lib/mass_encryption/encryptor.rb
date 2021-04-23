class MassEncryption::Encryptor
  DEFAULT_BATCH_SIZE = 1000

  def initialize(only: nil, except: nil, batch_size: DEFAULT_BATCH_SIZE)
    only = Array(only || all_encryptable_classes)
    except = Array(except)

    @encryptable_classes = only - except
    @batch_size = batch_size
    @silent = silent
  end

  def encrypt_all_later(sequential: true)
    encryptable_classes.each { enqueue_encryption_jobs_for(_1, sequential: sequential) }
  end

  private
    attr_reader :encryptable_classes, :batch_size, :silent

    EXCLUDED_FROM_AUTO_DETECTION = [ActionText::EncryptedRichText] # They get encrypted as part of the parent record

    def enqueue_encryption_jobs_for(klass, sequential: true)
      if sequential
        enqueue_sequential_encryption_jobs_for(klass)
      else
        enqueue_parallel_encryption_jobs_for(klass)
      end
    end

    def enqueue_sequential_encryption_jobs_for(klass)
      first_batch = MassEncryption::Batch.first_for(klass, size: batch_size)
      MassEncryption::BatchEncryptionJob.perform_later(first_batch, auto_enqueue_next: true)
    end

    def enqueue_parallel_encryption_jobs_for(klass)
      klass.in_batches(of: batch_size) do |records|
        batch = MassEncryption::Batch.new(klass: klass, from_id: records.first.id, size: batch_size)
        MassEncryption::BatchEncryptionJob.perform_later(batch, auto_enqueue_next: false)
      end
    end

    def all_encryptable_classes
      @all_encryptable_classes ||= begin
        Rails.application.eager_load! unless Rails.application.config.eager_load
        ActiveRecord::Base.descendants.find_all{ |klass| encryptable_class?(klass) } - EXCLUDED_FROM_AUTO_DETECTION
      end
    end

    def encryptable_class?(klass)
      has_encrypted_attributes?(klass) || has_encrypted_rich_text_attribute?(klass)
    end

    def has_encrypted_attributes?(klass)
      klass.encrypted_attributes.present?
    end

    def has_encrypted_rich_text_attribute?(klass)
      klass.reflect_on_all_associations(:has_one).find { |relation| relation.klass == ActionText::EncryptedRichText }
    end

    # Huge table freezes when counting with SQL. Extract count from stats instead.
    def count_from_table_stats(klass)
      result = klass.connection.execute("show table status like '#{klass.table_name}'")
      result.first[result.fields.index("Rows")]
    end
end

