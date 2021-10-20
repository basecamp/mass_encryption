class MassEncryption::Batch
  attr_reader :from_id, :size, :track, :tracks_count

  DEFAULT_BATCH_SIZE = 1000

  class << self
    def first_for(klass, size: DEFAULT_BATCH_SIZE, track: 0, tracks_count: 1)
      MassEncryption::Batch.new(klass: klass, from_id: klass.first.id, size: size, track: track, tracks_count: tracks_count) if klass.first
    end
  end

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
    if klass.encrypted_attributes.present?
      klass.upsert_all records.collect(&:attributes), on_duplicate: Arel.sql(encrypted_attributes_assignments_sql)
    end
  end

  def encrypt_later(auto_enqueue_next: false)
    MassEncryption::BatchEncryptionJob.perform_later(self, auto_enqueue_next: auto_enqueue_next)
  end

  def present?
    records.present? # we do want to load the association to avoid 2 queries
  end

  def next
    self.class.new(klass: klass, from_id: next_track_records.last.id + 1, size: size, track: track)
  end

  def records
    @records ||= klass.where("id >= ?", determine_from_id).order(id: :asc).limit(size)
  end

  private
    def encrypted_attributes_assignments_sql
      klass.encrypted_attributes.collect do |name|
        "`#{name}`=VALUES(`#{name}`)"
      end.join(", ")
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
      klass.where("id >= ?", from_id).order(id: :asc).limit(size + size * tracks_count)
    end
end
