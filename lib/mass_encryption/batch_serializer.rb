class MassEncryption::BatchSerializer < ActiveJob::Serializers::ObjectSerializer
  def serialize?(argument)
    argument.kind_of?(MassEncryption::Batch)
  end

  def serialize(batch)
    super(
      "klass" => batch.klass.name,
      "from_id" => batch.from_id,
      "size" => batch.size,
      "track" => batch.track || 0,
      "tracks_count" => batch.tracks_count || 1
    )
  end

  def deserialize(hash)
    MassEncryption::Batch.new(klass: hash["klass"].constantize, from_id: hash["from_id"], size: hash["size"], track: hash["track"], tracks_count: hash["tracks_count"])
  end
end
