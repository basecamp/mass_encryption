class MassEncryption::Encryptor
  DEFAULT_BATCH_SIZE = 1000

  def initialize(only: nil, except: nil, batch_size: DEFAULT_BATCH_SIZE, tracks_count: nil)
    only = Array(only || all_encryptable_classes)
    except = Array(except)

    @encryptable_classes = only - except
    @batch_size = batch_size
    @silent = silent
    @tracks_count = tracks_count
  end

  def encrypt_all_later
    encryptable_classes.each { |klass| enqueue_encryption_jobs_for(klass) }
  end

  private
    attr_reader :encryptable_classes, :batch_size, :silent, :tracks_count

    EXCLUDED_FROM_AUTO_DETECTION = [ ActionText::EncryptedRichText ] # They get encrypted as part of the parent record

    def enqueue_encryption_jobs_for(klass)
      if tracks_count.present?
        enqueue_track_encryption_jobs_for(klass)
      else
        enqueue_all_encryption_jobs_for(klass)
      end
    end

    def enqueue_all_encryption_jobs_for(klass)
      klass.in_batches(of: batch_size) do |records|
        MassEncryption::Batch.new(klass: klass, from_id: records.first.id, size: batch_size).encrypt_later(auto_enqueue_next: false)
      end
    end

    def enqueue_track_encryption_jobs_for(klass)
      tracks_count.times.each do |page|
        MassEncryption::Batch.first_for(klass, size: batch_size, page: page).encrypt_later(auto_enqueue_next: true)
      end
    end

    def all_encryptable_classes
      @all_encryptable_classes ||= begin
        Rails.application.eager_load! unless Rails.application.config.eager_load
        ActiveRecord::Base.descendants.find_all { |klass| encryptable_class?(klass) } - EXCLUDED_FROM_AUTO_DETECTION
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
end
