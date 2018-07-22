# Builds an OS X installer package from an installed formula.
require 'formula'
require 'optparse'
require 'tmpdir'

module HomebrewArgvExtension extend self
  def with_deps?
    flag? '--with-deps'
  end
end

# cribbed Homebrew module code from brew-unpack.rb
module Homebrew extend self
  def fpm
    unpack_usage = <<-EOS
Usage: brew fpm [--iteration iter] [--rpm] [--deb] [--with-deps] [--without-kegs] formula

Build an OS native installer package (deb, rpm) from a formula using fpm.
It must be already installed; 'brew fpm ' doesn't handle this for you automatically.

Options:
    EOS

 #    ARGS = { :shell=>'default', :writer=>'chm' } # Setting default values
 #    UNFLAGGED_ARGS = [ :formula ]              # Bare arguments (no flag)
 #    next_arg = UNFLAGGED_ARGS.first
 #    ARGV.each do |arg|
 #      case arg
 #      when '-h','--help'      then ARGS[:help]      = true
 #      when 'create'           then ARGS[:create]    = true
 #      when '-f','--force'     then ARGS[:force]     = true
 #      when '-n','--nopreview' then ARGS[:nopreview] = true
 #      when '-v','--version'   then ARGS[:version]   = true
 #      when '-s','--shell'     then next_arg = :shell
 #      when '-w','--writer'    then next_arg = :writer
 #      when '-o','--output'    then next_arg = :output
 #      when '-l','--logfile'   then next_arg = :logfile
 #      else
 #        if next_arg
 #          ARGS[next_arg] = arg
 #          UNFLAGGED_ARGS.delete( next_arg )
 #        end
 #        next_arg = UNFLAGGED_ARGS.first
 #      end
 #    end

    if ARGS[:help] or ARGV.empty?
      safe_system "fpm","--help"
      onoe unpack_usage
      abort
    end
    iteration = if ARGV.include? '--iteration'
        ARGV.next.chomp(".")
    else
      '1'
    end
    if ARGV.include? '--rpm'
      pkg_type = 'rpm'
    elsif ARGV.include? '--deb'
      pkg_type = 'deb'
    elsif File.exists? '/etc/redhat-release'
      pkg_type = 'rpm'
    else
      pkg_type = 'deb'
    end
    if pkg_type == 'rpm'
      if File.exists? '/etc/os-release'
        elvers = '7'
      else
        elvers = '6'
      end
    end
    if pkg_type == 'rpm'
      if File.exists? '/etc/os-release'
        elvers = '7'
      else
        elvers = '6'
      end
    end
    arch =  pkg_type == 'deb' ? 'amd64' : 'x86_64'
    extra_args = Array.new

    f = Formulary.factory ARGV.last
    # raise FormulaUnspecifiedError if formulae.empty?
    # formulae.each do |f|
    name = f.name
    # identifier = identifier_prefix + ".#{name}"
    prefix = "/usr/local"
    staging_prefix = ""
    version = f.version.to_s
    puts f.inspect

    #version += "_#{f.revision}" if f.revision.to_s != '0'

    # Make sure it's installed first
    if not f.installed?
      onoe "#{f.name} is not installed. First install it with 'brew install #{f.name}'."
      abort
    end

    # Setup staging dir
    pkg_root = Dir.mktmpdir 'brew-fpm'
    staging_root = pkg_root + HOMEBREW_PREFIX
    ohai "Creating package staging root using Homebrew prefix #{HOMEBREW_PREFIX}"
    FileUtils.mkdir_p staging_root


    pkgs = [f]

    # Add deps if we specified --with-deps
    pkgs += f.recursive_dependencies if ARGV.with_deps?

    pkgs.each do |pkg|
      formula = Formulary.factory(pkg.to_s)
      dep_version = formula.version.to_s
      #iteration = formula.revision.to_s if formula.revision != '0' and iteration != '0'
      dep_version += "_#{formula.revision}" if formula.revision.to_s != '0'


      ohai "Staging formula #{formula.name}"
      # Get all directories for this keg, rsync to the staging root

      if File.exists?(File.join(HOMEBREW_CELLAR, formula.name, dep_version))

        dirs = Pathname.new(File.join(HOMEBREW_CELLAR, formula.name, dep_version)).children.select { |c| c.directory? }.collect { |p| p.to_s }


        dirs.each {|d| safe_system "rsync", "-a", "--delete", "#{d}", "#{staging_root}/" }


        if File.exists?("#{HOMEBREW_CELLAR}/#{formula.name}/#{dep_version}") and not ARGV.include? '--without-kegs'

          ohai "Staging directory #{HOMEBREW_CELLAR}/#{formula.name}/#{dep_version}"

          safe_system "mkdir", "-p", "#{staging_root}#{staging_prefix}/#{formula.name}/"
          safe_system "rsync", "-a", "--delete", "#{HOMEBREW_CELLAR}/#{formula.name}/#{dep_version}", "#{staging_root}#{staging_prefix}/#{formula.name}/"
          ##safe_system "find","#{staging_root}#{staging_prefix}/#{formula.name}/"
        end

      end

      if formula.plist
        launch_daemon_dir = File.join staging_root, "Library", "LaunchDaemons"
        FileUtils.mkdir_p launch_daemon_dir
        fd = File.new(File.join(launch_daemon_dir, "#{formula.plist_name}.plist"), "w")
        fd.write formula.plist
        fd.close
      end
    end

    # Add scripts if we specified --scripts
    found_scripts = false
    if ARGV.include? '--scripts'
      scripts_path = ARGV.next
      if File.directory?(scripts_path)
        pre = File.join(scripts_path,"preinstall")
        post = File.join(scripts_path,"postinstall")
        if File.exists?(pre)
          File.chmod(0755, pre)
          found_scripts = true
          ohai "Adding preinstall script"
        end
        if File.exists?(post)
          File.chmod(0755, post)
          found_scripts = true
          ohai "Adding postinstall script"
        end
      end
      if not found_scripts
        opoo "No scripts found in #{scripts_path}"
      end
    end

    # Custom ownership
    found_ownership = false
    if ARGV.include? '--ownership'
      custom_ownership = ARGV.next
       if ['recommended', 'preserve', 'preserve-other'].include? custom_ownership
        found_ownership = true
        ohai "Setting fpm option --ownership with value #{custom_ownership}"
       else
        opoo "#{custom_ownership} is not a valid value for pkgbuild --ownership option, ignoring"
       end
    end

    if ARGV.include? '--os-dist'
      os_dist = ARGV.next
      if pkg_type == 'rpm'
        extra_args += ["--rpm-dist",os_dist]
      end
    end

    # Build it
    if pkg_type == 'deb'
      pkgfile = "#{name}_#{version}-#{iteration}_#{arch}.#{pkg_type}"
    elsif pkg_type == 'rpm'
      pkgfile = "#{name}-#{version}-#{iteration}.el#{elvers}.#{arch}.#{pkg_type}"
      extra_args += ["--rpm-autoreqprov"]
    end
    ohai "Building package #{pkgfile}"
    args = [
      "-s","dir",
      "-t", pkg_type,
      "-n","#{name}",
      "--description","#{f.desc}",
      "--url","#{f.homepage}",
      "--version", version,
      "--iteration", iteration,
      "--prefix", prefix,
    ] + extra_args + [
      "-f",
      "-C", staging_root, ".#{staging_prefix}"
    ]
    if found_scripts
      args << "--scripts"
      args << scripts_path
    end
    if found_ownership
      args << "--ownership"
      args << custom_ownership
    end
    #args << "#{pkgfile}"
    safe_system "fpm", *args

    FileUtils.rm_rf pkg_root
  end
end

Homebrew.fpm
