require "pathname"
require "time"

PROJ_DIR      = Pathname.new(__dir__)
APPS_DIR      = PROJ_DIR.join('apps')
GEMFILE       = PROJ_DIR.join('Gemfile')
INSTALL_ROOT  = Pathname.new(ENV["PREFIX"] || "/opt/ood")
VENDOR_BUNDLE = (ENV['VENDOR_BUNDLE'] == "yes" || ENV['VENDOR_BUNDLE'] == "true")

def apps
  Dir["#{APPS_DIR}/*"].map { |d| Component.new(d) }
end

class Component
  attr_reader :name
  attr_reader :path

  def initialize(app)
    @name = File.basename(app)
    @path = Pathname.new(app)
  end

  def ruby_app?
    @path.join('config.ru').exist?
  end

  def node_app?
    @path.join('app.js').exist?
  end
end

desc "Package OnDemand"
task :package do
  `which gtar 1>/dev/null 2>&1`
  if $?.success?
    tar = 'gtar'
  else
    tar = 'tar'
  end
  version = ENV['VERSION']
  if ! version
    latest_commit = `git rev-list --tags --max-count=1`.strip[0..6]
    latest_tag = `git describe --tags #{latest_commit}`.strip[1..-1]
    datetime = Time.now.strftime("%Y%m%d-%H%M")
    version = "#{latest_tag}-#{datetime}-#{latest_commit}"
  end
  sh "git ls-files | #{tar} -c --transform 's,^,ondemand-#{version}/,' -T - | gzip > packaging/v#{version}.tar.gz"
end

namespace :build do
  desc "Build gems"
  task :gems do
    if VENDOR_BUNDLE
      args = "--path vendor/bundle"
    else
      args = ""
    end
    apps.each do |a|
      next unless a.ruby_app?
      chdir a.path do
        sh "bundle install #{args}"
      end
    end
  end

  apps.each do |a|
    if a.ruby_app?
      depends = [:gems]
    else
      depends = []
    end
    task a.name.to_sym => depends do |t|
      setup_path = a.path.join("bin", "setup")
      if setup_path.exist? && setup_path.executable?
        sh "PASSENGER_APP_ENV=production #{setup_path}"
      end
    end
  end

  desc "Build all apps"
  task :all => apps.map { |a| a.name }
end

desc "Build OnDemand"
task :build => 'build:all'

directory INSTALL_ROOT.to_s

namespace :install do
  desc "Install OnDemand infrastructure"
  task :infrastructure => [INSTALL_ROOT] do
    sh "cp -r mod_ood_proxy #{INSTALL_ROOT}/"
    sh "cp -r nginx_stage #{INSTALL_ROOT}/"
    sh "cp -r ood_auth_map #{INSTALL_ROOT}/"
    sh "cp -r ood-portal-generator #{INSTALL_ROOT}/"
  end
  desc "Install OnDemand apps"
  task :apps => [INSTALL_ROOT] do
    sh "cp -r #{APPS_DIR} #{INSTALL_ROOT}/"
  end

  desc "Install OnDemand infrastructure and apps"
  task :all => [:infrastructure, :apps]
end

desc "Install OnDemand"
task :install => 'install:all'

desc "Clean up build"
task :clean do
  sh "git clean -Xdf"
end
