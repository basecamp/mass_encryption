module MassEncryption
  class Engine < ::Rails::Engine
    isolate_namespace MassEncryption

    initializer "mass_encryption.active_job" do
      config.active_job.custom_serializers << MassEncryption::BatchSerializer
    end
  end
end
