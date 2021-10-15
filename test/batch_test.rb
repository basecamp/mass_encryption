require "test_helper"

class BatchTest < ActiveSupport::TestCase
  test "encrypt the passed size" do
    MassEncryption::Batch.new(klass: Post, from_id: Post.first.id, size: 3).encrypt_now
    assert_encrypted_posts from: 0, to: 0 + 3 - 1
  end

  test "encrypt the passed with page" do
    MassEncryption::Batch.new(klass: Post, from_id: Post.third.id, size: 10, page: 2).encrypt_now
    assert_encrypted_posts from: 2 + 20 - 1, to: 2 + 20 + 10 - 1
  end

  test "next returns the next batch" do
    batch = MassEncryption::Batch.new(klass: Post, from_id: Post.first.id, size: 5, page: 2)
    next_batch = batch.next

    assert_equal Post.order(id: :asc)[5 - 1 + (2 * 5) - 1].id + 1, next_batch.from_id
    assert_equal Post,  next_batch.klass
    assert_equal 5,  next_batch.size
    assert_equal 2,  next_batch.page
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
    original_ciphertext = post.ciphertext_for(:title)

    MassEncryption::Batch.new(klass: Post, from_id: post.id, size: 1).encrypt_now
    assert_encrypted_record post.reload
    assert_not_equal original_ciphertext, post.ciphertext_for(:title)
  end

  test "encrypting won't change timestamps" do
    post = Post.first
    post.update_column :updated_at, 1.day.ago
    assert_no_changes ->{ post.reload.updated_at} do
      MassEncryption::Batch.new(klass: Post, from_id: post.id, size: 1).encrypt_now
    end
  end
end
