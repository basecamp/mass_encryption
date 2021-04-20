class MassEncryption::BatchSerializer < ActiveJob::Serializers::ObjectSerializer
  def serialize?(argument)
    argument.kind_of?(MassEncryption::Batch)
  end

  def serialize(batch)
    super(
      "klass" => batch.klass,
      "from_id" => batch.from_id,
      "size" => batch.size
    )
  end

  def deserialize(hash)
    MassEncryption::Batch.new(klass: hash["klass"], from_id: hash["from_id"], size: hash["size"])
  end
end
