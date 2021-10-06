module EncryptionTestHelper
  private
    def assert_everything_is_encrypted
      assert_encrypted_records Post.all
      assert_encrypted_records Person.all
      assert_encrypted_records ActionText::EncryptedRichText.all
    end

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

      if record.is_a?(ActionText::EncryptedRichText)
        assert_not clear_value.to_html.include?(encrypted_value)
      else
        assert_not_equal clear_value, encrypted_value
      end
      assert_equal clear_value, record.class.type_for_attribute(attribute_name).deserialize(encrypted_value)
    end

    def assert_not_encrypted_records(records)
      Array(records).each do |record|
        assert_not_encrypted_record record
      end
    end

    def assert_not_encrypted_record(record)
      encrypted_attributes = record.class.encrypted_attributes
      assert encrypted_attributes.present?
      encrypted_attributes.each do |attribute_name|
        assert_not_encrypted_attribute record, attribute_name
      end
    end

    def assert_not_encrypted_attribute(record, attribute_name)
      clear_value = record.public_send(attribute_name)
      encrypted_value = record.ciphertext_for(attribute_name)

      if record.is_a?(ActionText::EncryptedRichText)
        assert clear_value.to_html.include?(encrypted_value)
      else
        assert_equal clear_value, encrypted_value
      end
    end

    def assert_encrypted_posts(from:, to:)
      post_that_should_be_encrypted = Post.order(id: :asc)[from..to]

      assert_encrypted_records post_that_should_be_encrypted
      assert_not_encrypted_records Post.all - post_that_should_be_encrypted
    end
end
