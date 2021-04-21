require "test_helper"

class EncryptorTest < ActiveSupport::TestCase
  test "encrypt all the records sequentially" do
    perform_enqueued_jobs only: MassEncryption::BatchEncryptionJob do
      MassEncryption::Encryptor.new.encrypt_all_later(sequential: true)
    end

    assert_encrypted_records Post.all
    assert_encrypted_records Person.all
  end

  test "encrypt all the records in parallel" do
    perform_enqueued_jobs only: MassEncryption::BatchEncryptionJob do
      MassEncryption::Encryptor.new.encrypt_all_later(sequential: false)
    end

    assert_encrypted_records Post.all
    assert_encrypted_records Person.all
  end

  test "provide classes to encrypt" do
    perform_enqueued_jobs only: MassEncryption::BatchEncryptionJob do
      MassEncryption::Encryptor.new(only: [Person]).encrypt_all_later
    end

    assert_not_encrypted_records Post.all
    assert_encrypted_records Person.all
  end

  test "exclude records to encrypt" do
    perform_enqueued_jobs only: MassEncryption::BatchEncryptionJob do
      MassEncryption::Encryptor.new(except: [Person]).encrypt_all_later
    end

    assert_encrypted_records Post.all
    assert_not_encrypted_records Person.all
  end

  test "when running sequentially, it enqueues successive jobs until the whole batch is encrypted" do
    assert Post.count > 1

    MassEncryption::Encryptor.new(only: [Post], batch_size: 1).encrypt_all_later(sequential: true)
    assert_enqueued_jobs 1, only: MassEncryption::BatchEncryptionJob

    perform_enqueued_jobs only: MassEncryption::BatchEncryptionJob do
      MassEncryption::Encryptor.new(only: [Post], batch_size: 1).encrypt_all_later
    end

    assert_performed_jobs Post.count + 1, only: MassEncryption::BatchEncryptionJob
  end

  test "when running in parallel, it enqueues all the needed jobs to encrypt the batch" do
    assert Post.count > 1

    MassEncryption::Encryptor.new(only: [Post], batch_size: 1).encrypt_all_later(sequential: false)
    assert_enqueued_jobs Post.count, only: MassEncryption::BatchEncryptionJob

    perform_enqueued_jobs only: MassEncryption::BatchEncryptionJob do
      MassEncryption::Encryptor.new(only: [Post], batch_size: 1).encrypt_all_later(sequential: false)
    end

    assert_performed_jobs Post.count, only: MassEncryption::BatchEncryptionJob
  end
end
