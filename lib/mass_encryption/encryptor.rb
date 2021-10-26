class MassEncryption::Encryptor
  DEFAULT_BATCH_SIZE = 1000

  delegate :logger, to: MassEncryption

  def initialize(from_id: nil, only: nil, except: nil, batch_size: DEFAULT_BATCH_SIZE, tracks_count: nil, silent: true)
    only = Array(only || all_encryptable_classes)
    except = Array(except)

    @from_id = from_id
    @encryptable_classes = only - except
    @batch_size = batch_size
    @silent = silent
    @tracks_count = tracks_count

    logger.info info_message unless silent
  end

  def encrypt_all_later
    encryptable_classes.each { |klass| enqueue_encryption_jobs_for(klass) }
  end

  private
    attr_reader :from_id, :encryptable_classes, :batch_size, :silent, :tracks_count

    def info_message
      message = "Encrypting #{encryptable_classes.count} models"
      message << if execute_in_sequential_tracks?
        " with #{tracks_count} head jobs"
      else
        " with parallel jobs"
      end
      message << "\n\t#{encryptable_classes.collect(&:name).join(", ")}\n\n"

      message
    end

    def enqueue_encryption_jobs_for(klass)
      if execute_in_sequential_tracks?
        enqueue_track_encryption_jobs_for(klass)
      else
        enqueue_all_encryption_jobs_for(klass)
      end
    end

    def execute_in_sequential_tracks?
      tracks_count.present?
    end

    def enqueue_all_encryption_jobs_for(klass)
      all_records_for(klass).in_batches(of: batch_size) do |records|
        MassEncryption::Batch.new(klass: klass, from_id: records.first.id, size: batch_size).encrypt_later(auto_enqueue_next: false)
      end
    end

    def all_records_for(klass)
      base = klass
      base = base.where("id >= ?", from_id) if from_id.present?
      base
    end

    def enqueue_track_encryption_jobs_for(klass)
      tracks_count.times.each do |track|
        if first_record = all_records_for(klass).first
          MassEncryption::Batch.new(klass: klass, from_id: first_record.id, size: batch_size, track: track, tracks_count: tracks_count)&.encrypt_later(auto_enqueue_next: true)
        end
      end
    end

    def all_encryptable_classes
      @all_encryptable_classes ||= begin
        Rails.application.eager_load! unless Rails.application.config.eager_load
        ActiveRecord::Base.descendants.find_all { |klass| encryptable_class?(klass) }
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
