namespace :mass_encryption do
  task :encrypt_all_later, [:only, :except] => :environment do |task, args|
    only = classes_from(args[:only])
    except = classes_from(args[:except])

    MassEncryption::Encryptor.new(only: only, except: except).encrypt_all_later
  end

  def classes_from(string)
    if string.present?
      class_strings = string.split(/\s,/).filter(&:present?)
      class_strings.collect(&:constantize)
    end
  end
end
