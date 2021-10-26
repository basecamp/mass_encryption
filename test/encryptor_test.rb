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

  test "encrypt all with a from_id in parallel" do
    all_posts = Post.order(id: :asc)
    first_post_to_encrypt = all_posts.all[5]

    perform_enqueued_jobs only: MassEncryption::BatchEncryptionJob do
      MassEncryption::Encryptor.new(from_id: first_post_to_encrypt.id).encrypt_all_later
    end

    assert_encrypted_records all_posts.where("id >= ?", first_post_to_encrypt.id)
    assert_not_encrypted_records all_posts.where("id < ?", first_post_to_encrypt.id)
  end

  test "encrypt all with a from_id in tracks" do
    all_posts = Post.order(id: :asc)
    first_post_to_encrypt = all_posts.all[5]

    perform_enqueued_jobs only: MassEncryption::BatchEncryptionJob do
      MassEncryption::Encryptor.new(from_id: first_post_to_encrypt.id, tracks_count: 4, batch_size: 2).encrypt_all_later
    end

    assert_encrypted_records all_posts.where("id >= ?", first_post_to_encrypt.id)
    assert_not_encrypted_records all_posts.where("id < ?", first_post_to_encrypt.id)
  end

  test "encrypting in tracks create the expected tracks" do
    assert_enqueued_jobs 2, only: MassEncryption::BatchEncryptionJob do
      MassEncryption::Encryptor.new(only: Post, tracks_count: 2, batch_size: 2).encrypt_all_later
    end

    batch_1, batch_2 = enqueued_jobs.collect { |serialized_job| instantiate_job(serialized_job).arguments.first }.flatten

    assert_equal 0, batch_1.track
    assert_equal 1, batch_2.track
  end

  test "encrypting in tracks won't encrypt things more than once" do
    assert_enqueued_jobs 2, only: MassEncryption::BatchEncryptionJob do
      MassEncryption::Encryptor.new(only: Post, tracks_count: 2, batch_size: Post.count / 4).encrypt_all_later
    end

    batch_1_1, batch_1_2 = enqueued_jobs.collect { |serialized_job| instantiate_job(serialized_job).arguments.first }.flatten
    batch_1_1.encrypt_now
    batch_1_2.encrypt_now

    ciphertexts_by_post = (batch_1_1.records + batch_1_2.records).collect { |post| [ post, post.reload.ciphertext_for(:title) ] }.to_h

    batch_2_1, batch_2_2 = batch_1_1.next, batch_1_2.next
    batch_2_1.encrypt_now
    batch_2_2.encrypt_now

    assert_encrypted_records Post.order(id: :asc).all

    ciphertexts_by_post.each do |post, title_ciphertext|
      assert_equal title_ciphertext, post.reload.ciphertext_for(:title)
    end
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
