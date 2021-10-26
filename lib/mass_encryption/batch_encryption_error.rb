class MassEncryption::BatchEncryptionError < StandardError
  attr_reader :errors_by_record

  def initialize(errors_by_record)
    @errors_by_record = errors_by_record
    message = errors_by_record.collect { |record, error| "[#{record.class}:#{record.id}] #{error.inspect}" }.join(", ")
    super(message)
  end
end
