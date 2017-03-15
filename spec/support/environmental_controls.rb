# Helpers to assist with setting and unsetting environment variables
module EnvironmentalControls
  # Set some environment options, yield to a block and then put everything back as it was.
  #
  # @params [Hash<String, String>] env_options Hash of environment variables to be set
  def within_env(env_options)
    # Keep a note of what the environment variables are before we set them
    old_env_options = env_options.keys.each_with_object({}) { |env_key, hsh| hsh[env_key] = ENV[env_key] }

    self.environment = env_options
    yield if block_given?
  ensure
    # Put the original environment back
    self.environment = old_env_options
  end

  # Set the environment variables
  #
  # @params [Hash<String, String>] env_options Hash of environment variables to be set
  def environment=(env_options)
    env_options.each do |key, value|
      ENV[key] = value
    end
  end
end
