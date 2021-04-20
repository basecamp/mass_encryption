class MassEncryption::Batch
  attr_reader :from_id, :size

  DEFAULT_BATCH_SIZE = 1000

  class << self
    def first_for(klass, size: DEFAULT_BATCH_SIZE)
      MassEncryption::Batch.new(klass: klass, from_id: 0, size: size)
    end
  end

  def initialize(klass:, from_id:, size: DEFAULT_BATCH_SIZE)
    @class_name = klass.name # not storing class as instance variable as it causes stack overflow error with json serialization
    @from_id = from_id
    @size = size
  end

  def klass
    @class_name.constantize
  end

  def encrypt
    # Not using .upsert_all because MySQL is not fully supported (we'd need +unique_by:+ to be supported)
    records.each(&:encrypt)
  end

  def present?
    records.present? # we do want to load the association to avoid 2 queries
  end

  def next
    MassEncryption::Batch.new(klass: klass, from_id: records.last.id + 1, size: size)
  end

  private
    def records
      @records ||= klass.where("id >= ?", from_id).order(id: :asc).limit(size)
    end
end