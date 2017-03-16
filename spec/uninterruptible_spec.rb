require 'spec_helper'

describe Uninterruptible do
  it 'has a version number' do
    expect(Uninterruptible::VERSION).not_to be nil
  end

  it 'has the name of the environment variable file descriptors will be stored in' do
    expect(Uninterruptible::SERVER_FD_VAR).to be_a(String)
  end
end
