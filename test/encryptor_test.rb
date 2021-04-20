require "test_helper"

class EncryptorTest < ActiveSupport::TestCase
  test "encrypt all the records" do
    perform_enqueued_jobs only: [MassEncryption::BatchEncryptionJob, MassEncryption::EncryptionJobsEnqueuerJob] do
      MassEncryption::Encryptor.new.encrypt_all_later
    end

    assert_encrypted_records Post.all
    assert_encrypted_records Person.all
  end

  test "provide classes to encrypt" do
    perform_enqueued_jobs only: [MassEncryption::BatchEncryptionJob, MassEncryption::EncryptionJobsEnqueuerJob] do
      MassEncryption::Encryptor.new(only: [ Person ]).encrypt_all_later
    end

    assert_not_encrypted_records Post.all
    assert_encrypted_records Person.all
  end

  test "exclude records to encrypt" do
    perform_enqueued_jobs only: [MassEncryption::BatchEncryptionJob, MassEncryption::EncryptionJobsEnqueuerJob] do
      MassEncryption::Encryptor.new(except: [ Person ]).encrypt_all_later
    end

    assert_encrypted_records Post.all
    assert_not_encrypted_records Person.all
  end
end
