namespace :mass_encryption do
  task encrypt_all_in_tracks: :environment do
    from_id = ENV["FROM_ID"]
    only = MassEncryption::Tasks.classes_from(ENV["ONLY"])
    except = MassEncryption::Tasks.classes_from(ENV["EXCEPT"])
    tracks = (ENV["TRACKS"] || 1).to_i
    batch_size = (ENV["BATCH_SIZE"] || 1000).to_i

    MassEncryption::Encryptor.new(from_id: from_id, only: only, except: except, tracks_count: tracks, silent: false, batch_size: batch_size).encrypt_all_later
  end

  task encrypt_all_in_parallel_jobs: :environment do
    from_id = ENV["FROM_ID"]
    only = MassEncryption::Tasks.classes_from(ENV["ONLY"])
    except = MassEncryption::Tasks.classes_from(ENV["EXCEPT"])
    batch_size = (ENV["BATCH_SIZE"] || 1000).to_i

    MassEncryption::Encryptor.new(from_id: from_id, only: only, except: except, silent: false, batch_size: batch_size).encrypt_all_later
  end
end

module MassEncryption::Tasks
  extend self

  def classes_from(string)
    if string.present?
      class_strings = string.split(/[\s,]/).filter(&:present?)
      class_strings.collect(&:constantize)
    end
  end
end
