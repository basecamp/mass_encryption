class MassEncryption::Batch
  attr_reader :from_id, :size, :offset

  DEFAULT_BATCH_SIZE = 1000

  class << self
    def first_for(klass, size: DEFAULT_BATCH_SIZE, offset: 0)
      MassEncryption::Batch.new(klass: klass, from_id: klass.first.id, size: size, offset: offset)
    end
  end

  def initialize(klass:, from_id:, size: DEFAULT_BATCH_SIZE, offset: 0)
    @class_name = klass.name # not storing class as instance variable as it causes stack overflow error with json serialization
    @from_id = from_id
    @size = size
    @offset = offset
  end

  def klass
    @class_name.constantize
  end

  def encrypt_now
    # Not using .upsert_all because MySQL is not fully supported (we'd need +unique_by:+ to be supported)
    records.each(&:encrypt)
  end

  def encrypt_later(auto_enqueue_next: false)
    MassEncryption::BatchEncryptionJob.perform_later(self, auto_enqueue_next: auto_enqueue_next)
  end

  def present?
    records.present? # we do want to load the association to avoid 2 queries
  end

  def next
    self.class.new(klass: klass, from_id: records.last.id + 1, size: size, offset: offset)
  end

  private
    def records
      @records ||= klass.where("id >= ?", from_id).order(id: :asc).offset(offset).limit(size)
    end
end
