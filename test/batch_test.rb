require "test_helper"

class BatchTest < ActiveSupport::TestCase
  test "encrypting all the records" do
    batch = MassEncryption::Batch.new(klass: Post, from_id: Post.first.id, to_id: Post.last.id)
    batch.encrypt

    assert_encrypted_records Post.all
  end
end
