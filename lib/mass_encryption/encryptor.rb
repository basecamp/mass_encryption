class MassEncryption::Encryptor
  DEFAULT_BATCH_SIZE = 1000

  def initialize(only: nil, except: nil, batch_size: DEFAULT_BATCH_SIZE)
    only = Array(only || all_encryptable_classes)
    except = Array(except)

    @encryptable_classes = only - except
    @batch_size = batch_size
    @silent = silent
  end

  def encrypt_all_later
    encryptable_classes.each { enqueue_encryption_jobs_for(_1) }
  end

  private
    attr_reader :encryptable_classes, :batch_size, :silent

    def enqueue_encryption_jobs_for(klass)
      MassEncryption::EncryptionJobsEnqueuerJob.perform_later(klass: klass, batch_size: batch_size)
    end

    def all_encryptable_classes
      @all_encryptable_classes ||= begin
        Rails.application.eager_load! unless Rails.application.config.eager_load
        ActiveRecord::Base.descendants.find_all { |klass| klass.encrypted_attributes.present? }
      end
    end

    # Huge table freezes when counting with SQL. Extract count from stats instead.
    def count_from_table_stats(klass)
      result = klass.connection.execute("show table status like '#{klass.table_name}'")
      result.first[result.fields.index("Rows")]
    end
end

