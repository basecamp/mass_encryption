class MassEncryption::Batch
  attr_reader :from_id, :size, :track, :tracks_count

  DEFAULT_BATCH_SIZE = 1000

  delegate :logger, to: MassEncryption

  def initialize(klass:, from_id:, size: DEFAULT_BATCH_SIZE, track: 0, tracks_count: 1)
    @class_name = klass.name # not storing class as instance variable as it causes stack overflow error with json serialization
    @from_id = from_id
    @size = size
    @track = track
    @tracks_count = tracks_count
  end

  def klass
    @class_name.constantize
  end

  def encrypt_now
    if klass.encrypted_attributes.present? && present?
      validate_encrypting_is_allowed
      encrypt_records
    end
  end

  def validate_encrypting_is_allowed
    raise ActiveRecord::Encryption::Errors::Configuration, "can't mass encrypt while in protected mode" if ActiveRecord::Encryption.context.frozen_encryption?
  end

  def encrypt_later(auto_enqueue_next: false)
    MassEncryption::BatchEncryptionJob.perform_later(self, auto_enqueue_next: auto_enqueue_next)
  end

  def present?
    # we deliberately load the association to avoid 2 queries when checking if there are records
    # before encrypting in +MassEncryption::BatchEncryptionJob+
    records.present?
  end

  def next
    self.class.new(klass: klass, from_id: next_track_records.last.id + 1, size: size, track: track, tracks_count: tracks_count)
  end

  def records
    @records ||= klass.where("id >= ?", determine_from_id).order(id: :asc).limit(size)
  end

  def to_s
    "<#{klass}> from: #{from_id} size: #{size} (track=#{track}, tracks_count=#{tracks_count}) | #{records.first.id} - #{records.last.id}"
  end

  private
    def encrypt_records
      encrypt_using_upsert
    rescue StandardError => error
      logger.error "Upsert failed with #{error.inspect}. Trying to encrypt record by record..."
      encrypt_record_by_record
    end

    def encrypt_using_upsert
      klass.upsert_all records.collect(&:attributes), update_only: klass.encrypted_attributes, record_timestamps: false
    end

    def encrypt_record_by_record
      errors_by_record = {}

      records.each do |record|
        record.encrypt
      rescue StandardError => error
        errors_by_record[record] = error
      end

      raise MassEncryption::BatchEncryptionError.new(errors_by_record) if errors_by_record.present?
    end

    def determine_from_id
      if track == 0
        from_id # save a query to determine the id for the first track
      else
        last_track_id.present? ? (last_track_id + 1) : from_id
      end
    end

    def last_track_id
      @last_track_id ||= ids_in_the_same_track.last
    end

    def offset
      track * size
    end

    def ids_in_the_same_track
      klass.where("id >= ?", from_id).order(id: :asc).limit(offset).ids
    end

    def next_track_records
      klass.where("id >= ?", from_id).order(id: :asc).limit(size * tracks_count)
    end
end
