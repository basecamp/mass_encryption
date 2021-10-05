require "test_helper"

class BatchTest < ActiveSupport::TestCase
  test "encrypt the passed size" do
    MassEncryption::Batch.new(klass: Post, from_id: Post.first.id, size: 3).encrypt_now
    assert_encrypted_posts from: 0, to: 0 + 3 - 1
  end

  test "encrypt the passed with offset" do
    MassEncryption::Batch.new(klass: Post, from_id: Post.third.id, size: 10, offset: 3).encrypt_now
    assert_encrypted_posts from: 2 + 3, to: 2 + 3 + 10 - 1
  end

  test "next returns the next batch" do
    batch = MassEncryption::Batch.new(klass: Post, from_id: Post.first.id, size: 2, offset: 3)
    next_batch = batch.next

    assert_equal Post.order(id: :asc)[2 + 3 - 1].id + 1, next_batch.from_id
    assert_equal Post,  next_batch.klass
    assert_equal 2,  next_batch.size
    assert_equal 3,  next_batch.offset
  end

  test "present? returns whether there are records in the batch or not" do
    batch = MassEncryption::Batch.new(klass: Post, from_id: Post.last.id + 1, size: 100)
    assert_not batch.present?

    batch = MassEncryption::Batch.new(klass: Post, from_id: Post.first.id, size: 100)
    assert batch.present?
  end

  private
    def assert_encrypted_posts(from:, to:)
      post_that_should_be_encrypted = Post.order(id: :asc)[from..to]

      assert_encrypted_records post_that_should_be_encrypted
      assert_not_encrypted_records Post.all - post_that_should_be_encrypted
    end
end
