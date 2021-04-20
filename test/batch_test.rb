require "test_helper"

class BatchTest < ActiveSupport::TestCase
  test "encrypting all the records" do
    batch = MassEncryption::Batch.new(klass: Post, from_id: Post.first.id, size: 10)
    batch.encrypt

    assert_encrypted_records Post.all
  end

  test "only the passed size is encrypted" do
    batch = MassEncryption::Batch.new(klass: Post, from_id: Post.first.id, size: 1)
    batch.encrypt

    assert_encrypted_records Post.first
    assert_not_encrypted_records Post.all[1..]
  end

  test "next returns the next batch" do
    batch = MassEncryption::Batch.new(klass: Post, from_id: Post.first.id, size: 1)
    batch.encrypt

    assert_encrypted_records Post.first
    assert_not_encrypted_records Post.all[1..]

    next_batch = batch.next
    next_batch.encrypt

    assert_encrypted_records Post.all[1..]
  end

  test "present? returns whether there are records in the batch or not" do
    batch = MassEncryption::Batch.new(klass: Post, from_id: Post.last.id + 1, size: 100)
    assert_not batch.present?

    batch = MassEncryption::Batch.new(klass: Post, from_id: Post.first.id, size: 100)
    assert batch.present?
  end
end
