namespace :mass_encryption do
  task encrypt_all_in_tracks: :environment do
    from_id = ENV["FROM_ID"]
    only = classes_from(ENV["ONLY"])
    except = classes_from(ENV["EXCEPT"])
    tracks = (ENV["TRACKS"] || 1).to_i

    MassEncryption::Encryptor.new(from_id: from_id, only: only, except: except, tracks_count: tracks, silent: false).encrypt_all_later
  end

  task encrypt_all_in_parallel_jobs: :environment do
    from_id = ENV["FROM_ID"]
    only = classes_from(ENV["ONLY"])
    except = classes_from(ENV["EXCEPT"])

    MassEncryption::Encryptor.new(from_id: from_id, only: only, except: except, silent: false).encrypt_all_later
  end

  def classes_from(string)
    if string.present?
      class_strings = string.split(/[\s,]/).filter(&:present?)
      class_strings.collect(&:constantize)
    end
  end
end
