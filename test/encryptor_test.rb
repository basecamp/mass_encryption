require "test_helper"

class EncryptorTest < ActiveSupport::TestCase
  test "encrypt all the records in parallel" do
    perform_enqueued_jobs only: MassEncryption::BatchEncryptionJob do
      MassEncryption::Encryptor.new.encrypt_all_later
    end
    assert_everything_is_encrypted
  end

  test "encrypt all the records in tracks" do
    perform_enqueued_jobs only: MassEncryption::BatchEncryptionJob do
      MassEncryption::Encryptor.new(tracks_count: 4, batch_size: 2).encrypt_all_later
    end
    assert_everything_is_encrypted
  end

  test "encrypting in tracks create the expected tracks" do
    assert_enqueued_jobs 2, only: MassEncryption::BatchEncryptionJob do
      MassEncryption::Encryptor.new(only: Post, tracks_count: 2, batch_size: 2).encrypt_all_later
    end

    batch_1, batch_2 = enqueued_jobs.collect { |serialized_job| instantiate_job(serialized_job).arguments.first }.flatten

    assert_equal 0, batch_1.page
    assert_equal 1, batch_2.page
  end

  test "provide classes to encrypt" do
    perform_enqueued_jobs only: MassEncryption::BatchEncryptionJob do
      MassEncryption::Encryptor.new(only: [ Person ]).encrypt_all_later
    end

    assert_not_encrypted_records Post.all
    assert_not_encrypted_records ActionText::EncryptedRichText.all
    assert_encrypted_records Person.all
  end

  test "exclude records to encrypt" do
    perform_enqueued_jobs only: MassEncryption::BatchEncryptionJob do
      MassEncryption::Encryptor.new(except: [ Person ]).encrypt_all_later
    end

    assert_encrypted_records Post.all
    assert_encrypted_records ActionText::EncryptedRichText.all
    assert_not_encrypted_records Person.all
  end

  test "when running in tracks, it enqueues successive jobs until the whole batch is encrypted" do
    assert Post.count > 1

    MassEncryption::Encryptor.new(only: [ Post ], batch_size: 1, tracks_count: 1).encrypt_all_later
    assert_enqueued_jobs 1, only: MassEncryption::BatchEncryptionJob

    perform_enqueued_jobs only: MassEncryption::BatchEncryptionJob do
      MassEncryption::Encryptor.new(only: [ Post ], batch_size: 1).encrypt_all_later
    end

    assert_performed_jobs Post.count, only: MassEncryption::BatchEncryptionJob
  end

  test "when running in parallel, it enqueues all the needed jobs to encrypt the batch" do
    assert Post.count > 1

    MassEncryption::Encryptor.new(only: [ Post ], batch_size: 1).encrypt_all_later
    assert_enqueued_jobs Post.count, only: MassEncryption::BatchEncryptionJob

    perform_enqueued_jobs only: MassEncryption::BatchEncryptionJob do
      MassEncryption::Encryptor.new(only: [ Post ], batch_size: 1).encrypt_all_later
    end

    assert_performed_jobs Post.count, only: MassEncryption::BatchEncryptionJob
  end

  test "encrypting includes encrypted rich texts attributes" do
    perform_enqueued_jobs only: MassEncryption::BatchEncryptionJob do
      MassEncryption::Encryptor.new.encrypt_all_later
    end

    assert_encrypted_records ActionText::EncryptedRichText.all
  end

  test "don't fail when there are no records to encrypt" do
    Post.delete_all

    assert_nothing_raised do
      perform_enqueued_jobs only: MassEncryption::BatchEncryptionJob do
        MassEncryption::Encryptor.new.encrypt_all_later
      end
    end

    assert_nothing_raised do
      perform_enqueued_jobs only: MassEncryption::BatchEncryptionJob do
        MassEncryption::Encryptor.new(tracks_count: 1).encrypt_all_later
      end
    end
  end
end
