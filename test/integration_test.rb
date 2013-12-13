require_relative "test_helper"

describe "CLI" do
  def sh(cmd, options={})
    result = `#{cmd} 2>&1`
    raise "FAILED #{cmd} --> #{result}" if $?.success? != !options[:fail]
    result
  end

  def spelunk(command, options={})
    sh "#{File.expand_path("../../bin/git-spelunk", __FILE__)} #{command}", options
  end

  it "shows version" do
    version = /\A\d+\.\d+\.\d+\Z/m
    spelunk("--version").must_match version
    spelunk("-v").must_match version
  end

  it "shows help" do
    spelunk("--help").must_include "Usage"
    spelunk("-h").must_include "Usage"
  end
end
