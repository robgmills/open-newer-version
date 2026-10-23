require "tempfile"

module Eneroth
  module OpenNewerVersion
    module OpenNewer
      # Major version of the running SketchUp.
      SU_VERSION = Sketchup.version.to_i

      # Get SketchUp version string of a saved file.
      #
      # @param path [String]
      #
      # @raise [IOError]
      #
      # @return [String]
      def self.version(path)
        v = File.binread(path, 64).tr("\x00", "")[/{([\d.]+)}/n, 1]

        v || raise(IOError, "Can't determine SU version for '#{path}'. Is file a model?")
      end

      # Ask user for path to open from.
      #
      # @return [String]
      def self.prompt_source_path
        UI.openpanel("Open", "", "SketchUp Models|*.skp||")
      end

      # Ask user for path to save converted model to.
      #
      # @param source [String]
      #
      # @return [String]
      def self.prompt_target_path(source)
        # Prefixing version with 20 as SketchUp 2014 is the oldest supported
        # version. If ever supporting versions 8 or older, only prefix for
        # [20]13 and above.
        title = "Save As SketchUp 20#{SU_VERSION} Compatible"
        directory = File.dirname(source)
        filename = "#{File.basename(source, '.skp')} (SU 20#{SU_VERSION}).skp"

        UI.savepanel(title, directory, filename)
      end

      # Run system call without flashing command line window on Windows.
      # Runs asynchronously.
      #
      # @param args [Array<String>]
      #
      # @return [Void].
      def self.system_call(args)
        if platform_win?
          # HACK: Run the command through a VBS script to avoid flashing command line
          # window.
          cmd = args.map { |arg| arg.to_s.gsub('"', '""') }
          command = cmd.map { |arg| "\"#{arg}\"" }.join(" ")
          file = Tempfile.new(["cmd", ".vbs"])
          file.write("Set WshShell = CreateObject(\"WScript.Shell\")\n")
          file.write("WshShell.Run \"#{command}\", 0\n")
          file.close
          UI.openURL("file://#{file.path}")
          return nil
        end

        pid = spawn(*args)
        Process.detach(pid)

        nil
      end

      # Get platform identifier used by the plugin.
      #
      # @return [Symbol]
      def self.platform
        Sketchup.platform
      end

      # @return [Boolean]
      def self.platform_win?
        platform == :platform_win
      end

      # @return [Boolean]
      def self.platform_osx?
        platform == :platform_osx
      end

      # @return [String]
      def self.platform_label
        return "Windows" if platform_win?
        return "macOS" if platform_osx?

        platform.to_s
      end

      # @return [String]
      def self.converter_path
        filename = if platform_win?
          "ConvertVersion.exe"
        else
          "ConvertVersion-mac"
        end
        File.join(PLUGIN_DIR, "bin", filename)
      end

      # @return [Boolean]
      def self.converter_present?
        File.exist?(converter_path)
      end

      # @return [Boolean]
      def self.ensure_converter_present
        return true if converter_present?

        UI.messagebox(
          "Missing converter for #{platform_label}. " \
          "Please install the platform-specific converter binary."
        )
        false
      end

      # Run block once a file has been created.
      #
      # @param path [String]
      # @param async [Boolean]
      # @param delay [Flaot]
      # @param block [Proc]
      #
      # @return [Void]
      def self.on_exist(path, async = true, delay = 0.2, &block)
        if File.exist?(path)
          block.call
          return
        end

        if async
          UI.start_timer(delay) { on_exist(path, async, delay, &block) }
        else
          sleep(delay)
          on_exist(path, async, delay, &block)
        end

        nil
      end

      # Convert an external model to the current SU version and open it.
      #
      # @param source [String]
      # @param target [String]
      #
      # @return [Void]
      def self.convert_and_open(source, target)
        return unless ensure_converter_present

        Sketchup.status_text = "Converting model to supported format..."

        # Since the hack for running the system command without a flashing window
        # makes the call asynchronous, we need to wait to open the converted model
        # until its file exists. To check for file creation, we must first make sure
        # there is no existing file by the same name already.
        File.delete(target) if File.exist?(target)

        system_call([converter_path, source, target, SU_VERSION.to_s])
        on_exist(target, false) { Sketchup.open_file(target) }

        nil
      end

      # Ask for path to open, convert if needed and open.
      #
      # @return [Void]
      def self.open_newer_version
        source = prompt_source_path || return
        version = version(source).to_i
        if version <= SU_VERSION
          Sketchup.open_file(source)
          return
        end
        target = prompt_target_path(source) || return
        convert_and_open(source, target)

        nil
      end
    end
  end
end
