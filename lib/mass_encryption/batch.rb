class MassEncryption::Batch
  attr_reader :klass, :from_id, :to_id

  def initialize(klass:, from_id:, to_id:)
    @klass = klass
    @from_id = from_id
    @to_id = to_id
  end

  def encrypt
    # Not using .upsert_all because MySQL is not fully supported (we'd need +unique_by:+ to be supported)
    klass.where(id: from_id..to_id).find_each(&:encrypt)
  end
end