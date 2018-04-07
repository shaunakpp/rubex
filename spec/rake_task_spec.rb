require 'spec_helper'
require 'rubex/rake_task'

describe Rubex::RakeTask, hell: true do
  context "#files" do
    it "specifies rubex files for a multi-file compile" do
      files = ["foo.rubex", "bar.rubex", "bar.rubex"]
      task = Rubex::RakeTask.new("test") do
        files files
      end

      expect(task.rubex_files).to eq(files)
    end
  end

  context "#ext" do
    before do
      @task_name = "test"
    end
    
    it "assumes default dir for ext in a gem" do
      task = Rubex::RakeTask.new(@task_name)
      expect(task.ext_dir).to eq("#{Dir.pwd}/ext/#{@task_name}")
    end

    it "allows user to set the ext directory" do
      task = Rubex::RakeTask.new(@task_name) do
        ext Dir.pwd
      end
      expect(task.ext_dir).to eq(Dir.pwd)
    end
  end
end

describe "rake", hell: true do
  context "rubex:compile" do
    before do
      Rake::Task.clear
    end
    
    it "compiles a single file program" do
      ext_path = "#{Dir.pwd}/spec/fixtures/rake_task/single_file"
      name = "test"
      Rubex::RakeTask.new(name) do
        ext ext_path
      end
      Rake::Task["rubex:compile"].invoke

      expect(File.exist?("#{ext_path}/#{name}/#{name}.c")).to eq(true)
      expect(File.exist?("#{ext_path}/#{name}/extconf.rb")).to eq(true)

      # delete generated files
      dir = "#{ext_path}/#{name}"
      Dir.chdir(dir) do
        FileUtils.rm(
          Dir.glob(
          "#{dir}/#{name}.{c,so,o,bundle,dll}") + ["Makefile", "extconf.rb"], force: true
        )
      end
      FileUtils.rmdir(dir)
    end

    it "compiles a multiple file program" do
      Rubex::RakeTask.new("test") do
        ext "#{Dir.pwd}/fixtures/rake_task/multi_file"
        files ["a.rubex", "test.rubex"]
      end
      Rake::Task["rubex:compile"].invoke      
    end
  end
end
