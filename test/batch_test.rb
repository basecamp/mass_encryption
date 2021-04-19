require "test_helper"

class BatchTest < ActiveSupport::TestCase
  test "encrypting all the records" do
    batch = MassEncryption::Batch.new(klass: Post, from_id: Post.first.id, to_id: Post.last.id)
    batch.encrypt

    assert_encrypted_records Post.all
  end

  private
    def assert_encrypted_records(records)
      Array(records).each do |record|
        assert_encrypted_record record
      end
    end

    def assert_encrypted_record(record)
      encrypted_attributes = record.class.encrypted_attributes
      assert encrypted_attributes.present?
      encrypted_attributes.each do |attribute_name|
        assert_encrypted_attribute record, attribute_name
      end
    end

    def assert_encrypted_attribute(record, attribute_name)
      clear_value = record.public_send(attribute_name)
      encrypted_value = record.ciphertext_for(attribute_name)

      assert_not_equal clear_value, encrypted_value
      assert_equal clear_value, record.class.type_for_attribute(attribute_name).deserialize(encrypted_value)
    end
end
