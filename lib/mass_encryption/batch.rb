class MassEncryption::Batch
  attr_reader :from_id, :size, :page

  DEFAULT_BATCH_SIZE = 1000

  class << self
    def first_for(klass, size: DEFAULT_BATCH_SIZE, page: 0)
      MassEncryption::Batch.new(klass: klass, from_id: klass.first.id, size: size, page: page)
    end
  end

  def initialize(klass:, from_id:, size: DEFAULT_BATCH_SIZE, page: 0)
    @class_name = klass.name # not storing class as instance variable as it causes stack overflow error with json serialization
    @from_id = from_id
    @size = size
    @page = page
  end

  def klass
    @class_name.constantize
  end

  def encrypt_now
    klass.upsert_all records.collect(&:attributes)
  end

  def encrypt_later(auto_enqueue_next: false)
    MassEncryption::BatchEncryptionJob.perform_later(self, auto_enqueue_next: auto_enqueue_next)
  end

  def present?
    records.present? # we do want to load the association to avoid 2 queries
  end

  def next
    self.class.new(klass: klass, from_id: records.last.id + 1, size: size, page: page)
  end

  private
    def records
      @records ||= klass.where("id >= ?", determine_from_id).order(id: :asc).limit(size)
    end

    def determine_from_id
      if page == 0
        from_id # save a query to determine the id for the first page
      else
        ids_in_the_same_track[offset - 1] || from_id
      end
    end

    def offset
      page * size
    end

    def ids_in_the_same_track
      klass.where("id >= ?", from_id).order(id: :asc).limit(offset).pluck(:id)
    end
end
