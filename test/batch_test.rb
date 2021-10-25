require "test_helper"

class BatchTest < ActiveSupport::TestCase
  test "encrypt the passed size" do
    MassEncryption::Batch.new(klass: Post, from_id: Post.first.id, size: 3).encrypt_now
    assert_encrypted_posts from: 0, to: 0 + 3 - 1
  end

  test "encrypting will keep the data intact" do
    expected_properties = Post.first(20).collect(&:attributes)

    MassEncryption::Batch.new(klass: Post, from_id: Post.first.id, size: 20).encrypt_now

    assert_encrypted_posts from: 0, to: 19
    assert_equal expected_properties, Post.first(20).collect(&:attributes)
  end

  test "encrypting won't insert new data" do
    assert_no_changes ->{ Post.count }do
      MassEncryption::Batch.new(klass: Post, from_id: Post.first.id).encrypt_now
    end
  end

  test "encrypt considering the provided track" do
    MassEncryption::Batch.new(klass: Post, from_id: Post.third.id, size: 10, track: 2).encrypt_now
    assert_encrypted_posts from: 2 + 20, to: 2 + 20 + 10 - 1
  end

  test "next returns the next batch" do
    batch = MassEncryption::Batch.new(klass: Post, from_id: Post.first.id, size: 5, track: 2, tracks_count: 3)
    next_batch = batch.next

    assert_equal Post.order(id: :asc)[(3 * 5) - 1].id + 1, next_batch.from_id
    assert_equal Post, next_batch.klass
    assert_equal 5, next_batch.size
    assert_equal 2, next_batch.track
    assert_equal 3, next_batch.tracks_count
  end

  test "present? returns whether there are records in the batch or not" do
    batch = MassEncryption::Batch.new(klass: Post, from_id: Post.last.id + 1, size: 100)
    assert_not batch.present?

    batch = MassEncryption::Batch.new(klass: Post, from_id: Post.first.id, size: 100)
    assert batch.present?
  end

  test "encrypting actually re-encrypts encrypted data" do
    post = Post.first
    post.encrypt
    assert_encrypted_record post
    original_title = post.title
    original_ciphertext = post.ciphertext_for(:title)

    MassEncryption::Batch.new(klass: Post, from_id: post.id, size: 1).encrypt_now
    assert_encrypted_record post.reload
    assert_not_equal original_ciphertext, post.ciphertext_for(:title)
    assert_equal original_title, post.title
  end

  test "encrypting won't change timestamps" do
    post = Post.first
    post.update_column :updated_at, 1.day.ago
    assert_no_changes -> { post.reload.updated_at } do
      MassEncryption::Batch.new(klass: Post, from_id: post.id, size: 1).encrypt_now
    end
  end

  test "raise an error when trying to encrypt in encryption-protected mode" do
    assert_raise ActiveRecord::Encryption::Errors::Configuration do
      ActiveRecord::Encryption.protecting_encrypted_data do
        MassEncryption::Batch.new(klass: Post, from_id: 0, size: 1).encrypt_now
      end
    end
  end
end
