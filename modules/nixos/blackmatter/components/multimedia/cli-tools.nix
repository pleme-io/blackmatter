# Multimedia & Content Tools - Complete Media Arsenal
{ config, lib, pkgs, ... }:
let
  cfg = config.blackmatter.multimedia.cliTools;
  errors = import ../../../../lib/errors.nix { inherit lib; };
in {
  options.blackmatter.multimedia.cliTools = with lib; {
    enable = mkEnableOption "Comprehensive multimedia and content tools for CLI/TUI";
    
    audioPlayers = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable CLI/TUI audio players";
      };
      
      includeAdvanced = mkOption {
        type = types.bool;
        default = true;
        description = "Include advanced audio players (cmus, ncmpcpp)";
      };
      
      includeGUI = mkOption {
        type = types.bool;
        default = true;
        description = "Include GUI-capable players (mpv, vlc)";
      };
    };
    
    audioTools = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable audio processing and conversion tools";
      };
      
      includeConverters = mkOption {
        type = types.bool;
        default = true;
        description = "Include audio conversion tools (sox, ffmpeg)";
      };
      
      includeDownloaders = mkOption {
        type = types.bool;
        default = true;
        description = "Include media downloaders (youtube-dl, yt-dlp)";
      };
      
      includeAnalysis = mkOption {
        type = types.bool;
        default = true;
        description = "Include audio analysis tools";
      };
    };
    
    videoTools = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable video processing and analysis tools";
      };
      
      includeProcessing = mkOption {
        type = types.bool;
        default = true;
        description = "Include video processing tools";
      };
      
      includeAnalysis = mkOption {
        type = types.bool;
        default = true;
        description = "Include video analysis tools (mediainfo, exiftool)";
      };
    };
    
    imageTools = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable image processing and manipulation tools";
      };
      
      includeProcessing = mkOption {
        type = types.bool;
        default = true;
        description = "Include image processing tools (imagemagick)";
      };
      
      includeTextArt = mkOption {
        type = types.bool;
        default = true;
        description = "Include text art and ASCII tools (figlet, toilet)";
      };
      
      includeViewing = mkOption {
        type = types.bool;
        default = true;
        description = "Include terminal image viewers";
      };
    };
    
    documentTools = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable document processing and conversion tools";
      };
      
      includeConversion = mkOption {
        type = types.bool;
        default = true;
        description = "Include document conversion tools (pandoc)";
      };
      
      includeFormatting = mkOption {
        type = types.bool;
        default = true;
        description = "Include document formatting tools (groff, asciidoc)";
      };
    };
    
    presentationTools = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable terminal presentation tools";
      };
    };
  };
  
  config = lib.mkIf cfg.enable (lib.mkMerge [
    # Base validation
    {
      assertions = [
        {
          assertion = cfg.audioPlayers.enable || cfg.audioTools.enable || 
                     cfg.videoTools.enable || cfg.imageTools.enable || 
                     cfg.documentTools.enable;
          message = errors.format.formatError (
            errors.types.configError "At least one multimedia category must be enabled" {
              available = "audioPlayers, audioTools, videoTools, imageTools, documentTools";
            }
          );
        }
      ];
    }
    
    # Audio Players Collection
    (lib.mkIf cfg.audioPlayers.enable {
      environment.systemPackages = with pkgs; 
        errors.recovery.withDefault [] (
          # Advanced CLI/TUI audio players
          (lib.optionals cfg.audioPlayers.includeAdvanced [
            cmus                   # Small, fast and powerful console music player
            ncmpcpp               # MPD client with tag editor and playlist editor
            moc                   # Music On Console - simple curses audio player
            mpd                   # Music Player Daemon
            mpc-cli               # Command-line client for MPD
            musikcube             # Cross-platform, terminal-based music player
          ]) ++
          
          # GUI-capable players that work in terminal
          (lib.optionals cfg.audioPlayers.includeGUI [
            mpv                   # General-purpose media player (CLI/GUI)
            vlc                   # Cross-platform multimedia player
            mplayer               # Cross-platform multimedia player
            ffplay                # Simple media player using FFmpeg libraries
          ]) ++
          
          # Specialized audio players
          [
            alsamixer             # ALSA mixer program
            pulsemixer            # CLI PulseAudio mixer
            pamixer               # PulseAudio command-line mixer
            playerctl             # Command-line utility for media player control
            cava                  # Console-based audio visualizer
          ]
        );
        
      # Audio player aliases and functions
      environment.shellAliases = {
        music = "cmus";
        player = "mpv";
        audio = "cmus";
        mixer = "alsamixer";
        volume = "pamixer";
        visualizer = "cava";
        mpd-client = "ncmpcpp";
        play = "mpv";
        pause = "playerctl pause";
        next = "playerctl next";
        prev = "playerctl previous";
        stop = "playerctl stop";
      };
      
      # Audio functions
      environment.shellInit = ''
        # Quick play function
        qplay() {
          if [ -z "$1" ]; then
            echo "Usage: qplay <audio-file-or-url>"
            return 1
          fi
          mpv --no-video "$1"
        }
        
        # Volume control
        vol() {
          case "$1" in
            up)
              pamixer -i "''${2:-5}"
              ;;
            down)
              pamixer -d "''${2:-5}"
              ;;
            mute)
              pamixer -m
              ;;
            unmute)
              pamixer -u
              ;;
            set)
              if [ -n "$2" ]; then
                pamixer --set-volume "$2"
              else
                echo "Usage: vol set <percentage>"
              fi
              ;;
            *)
              echo "Current volume: $(pamixer --get-volume)%"
              echo "Usage: vol {up|down|mute|unmute|set} [value]"
              ;;
          esac
        }
        
        # Music control
        music-control() {
          case "$1" in
            play)
              playerctl play
              ;;
            pause)
              playerctl pause
              ;;
            toggle)
              playerctl play-pause
              ;;
            next)
              playerctl next
              ;;
            prev)
              playerctl previous
              ;;
            stop)
              playerctl stop
              ;;
            status)
              playerctl status
              ;;
            info)
              echo "Artist: $(playerctl metadata artist)"
              echo "Title: $(playerctl metadata title)"
              echo "Album: $(playerctl metadata album)"
              ;;
            *)
              echo "Usage: music-control {play|pause|toggle|next|prev|stop|status|info}"
              ;;
          esac
        }
      '';
    })
    
    # Audio Tools Collection
    (lib.mkIf cfg.audioTools.enable {
      environment.systemPackages = with pkgs; 
        errors.recovery.withDefault [] (
          # Audio conversion and processing
          (lib.optionals cfg.audioTools.includeConverters [
            sox                   # Sound processing library
            ffmpeg                # Complete multimedia framework
            lame                  # High quality MP3 encoder
            flac                  # Free Lossless Audio Codec
            vorbis-tools          # Ogg Vorbis encoder/decoder
            opus-tools            # Opus audio codec tools
            wavpack               # Hybrid lossless audio compression
            mac                   # Monkey's Audio Codec
            shntool               # Multi-purpose WAVE data processing tool
          ]) ++
          
          # Media downloaders
          (lib.optionals cfg.audioTools.includeDownloaders [
            yt-dlp                # Feature-rich command-line audio/video downloader
            youtube-dl            # Download videos from YouTube and other sites
            aria2                 # Multi-protocol download utility
            wget                  # Network downloader
            curl                  # Data transfer tool
            streamlink            # CLI for extracting streams from websites
          ]) ++
          
          # Audio analysis and utilities
          (lib.optionals cfg.audioTools.includeAnalysis [
            mediainfo             # Display technical information about media files
            exiftool              # Read and write meta information in files
            aubio                 # Audio labelling tools
            beets                 # Music library manager and MusicBrainz tagger
            picard                # MusicBrainz Picard audio tagger
            kid3                  # Audio tag editor
            puddletag             # Audio tag editor
          ]) ++
          
          # Audio utilities
          [
            cdparanoia            # CD ripper
            cdrdao                # CD burning tool
            normalize             # Audio file volume normalizer
            bs1770gain            # EBU R128 loudness scanner
            r128gain              # Fast audio loudness scanner
            replaygain            # ReplayGain volume normalization
          ]
        );
        
      # Audio tools aliases
      environment.shellAliases = {
        dl = "yt-dlp";
        download = "yt-dlp";
        ytdl = "yt-dlp";
        audio-dl = "yt-dlp -x";
        mp3-dl = "yt-dlp -x --audio-format mp3";
        convert-audio = "ffmpeg";
        audio-info = "mediainfo";
        tag-music = "beets";
        normalize-audio = "normalize";
        rip-cd = "cdparanoia";
      };
      
      # Audio processing functions
      environment.shellInit = ''
        # Download audio from URL
        audio-download() {
          if [ -z "$1" ]; then
            echo "Usage: audio-download <url> [format]"
            return 1
          fi
          local format="''${2:-mp3}"
          yt-dlp -x --audio-format "$format" "$1"
        }
        
        # Convert audio format
        audio-convert() {
          if [ $# -lt 3 ]; then
            echo "Usage: audio-convert <input> <output> <format>"
            echo "Formats: mp3, flac, ogg, wav, m4a"
            return 1
          fi
          ffmpeg -i "$1" "$2"
        }
        
        # Extract audio from video
        extract-audio() {
          if [ -z "$1" ]; then
            echo "Usage: extract-audio <video-file> [output-format]"
            return 1
          fi
          local input="$1"
          local format="''${2:-mp3}"
          local output="''${input%.*}.$format"
          ffmpeg -i "$input" -vn -acodec libmp3lame "$output"
        }
        
        # Get audio information
        audio-analyze() {
          if [ -z "$1" ]; then
            echo "Usage: audio-analyze <audio-file>"
            return 1
          fi
          echo "=== Audio File Analysis ==="
          mediainfo "$1"
          echo ""
          echo "=== Technical Details ==="
          ffprobe -v quiet -print_format json -show_format -show_streams "$1" 2>/dev/null | jq -r '
            .format | 
            "Duration: \(.duration)s",
            "Bitrate: \(.bit_rate) bps",
            "Size: \(.size) bytes"
          ' 2>/dev/null || echo "Install jq for JSON parsing"
        }
      '';
    })
    
    # Video Tools Collection
    (lib.mkIf cfg.videoTools.enable {
      environment.systemPackages = with pkgs; 
        errors.recovery.withDefault [] (
          # Video processing tools
          (lib.optionals cfg.videoTools.includeProcessing [
            ffmpeg                # Complete multimedia framework
            x264                  # H.264 video encoder
            x265                  # H.265/HEVC video encoder
            xvid                  # MPEG-4 video codec
            libvpx                # VP8/VP9 video codec
            av1-analyzer          # AV1 bitstream analyzer
            # handbrake           # Disabled: ffmpeg-full LCEVC compatibility
            dvdbackup             # DVD backup tool
          ]) ++
          
          # Video analysis tools
          (lib.optionals cfg.videoTools.includeAnalysis [
            mediainfo             # Media information analyzer
            exiftool              # Metadata reader/writer
            ffprobe               # Multimedia stream analyzer
            mkvtoolnix            # Matroska tools
            mp4v2                 # MP4 library and tools
            atomicparsley         # MPEG-4 metadata tool
          ]) ++
          
          # Video utilities
          [
            youtube-dl            # Video downloader
            yt-dlp                # Enhanced video downloader
            streamlink            # Stream extractor
            v4l-utils             # Video4Linux utilities
            obs-studio            # Video recording and streaming
          ]
        );
        
      # Video tools aliases
      environment.shellAliases = {
        video-dl = "yt-dlp";
        video-info = "mediainfo";
        video-convert = "ffmpeg";
        transcode = "handbrake";
        analyze-video = "ffprobe";
        mkv-info = "mkvinfo";
        video-meta = "exiftool";
      };
      
      # Video processing functions
      environment.shellInit = ''
        # Download video
        video-download() {
          if [ -z "$1" ]; then
            echo "Usage: video-download <url> [quality]"
            echo "Quality options: best, worst, 720p, 1080p, etc."
            return 1
          fi
          local quality="''${2:-best}"
          yt-dlp -f "$quality" "$1"
        }
        
        # Convert video format
        video-convert() {
          if [ $# -lt 2 ]; then
            echo "Usage: video-convert <input> <output> [options]"
            return 1
          fi
          ffmpeg -i "$1" "$2" "''${@:3}"
        }
        
        # Compress video
        video-compress() {
          if [ -z "$1" ]; then
            echo "Usage: video-compress <input-file> [output-file] [crf]"
            echo "CRF: 18-28 (lower = better quality, higher file size)"
            return 1
          fi
          local input="$1"
          local output="''${2:-''${input%.*}_compressed.''${input##*.}}"
          local crf="''${3:-23}"
          ffmpeg -i "$input" -c:v libx264 -crf "$crf" -c:a aac -b:a 128k "$output"
        }
        
        # Extract frames from video
        video-frames() {
          if [ -z "$1" ]; then
            echo "Usage: video-frames <video-file> [fps] [output-pattern]"
            return 1
          fi
          local input="$1"
          local fps="''${2:-1}"
          local pattern="''${3:-frame_%04d.png}"
          ffmpeg -i "$input" -vf fps="$fps" "$pattern"
        }
        
        # Video information
        video-analyze() {
          if [ -z "$1" ]; then
            echo "Usage: video-analyze <video-file>"
            return 1
          fi
          echo "=== Video File Analysis ==="
          mediainfo "$1"
          echo ""
          echo "=== Technical Details ==="
          ffprobe -v quiet -print_format json -show_format -show_streams "$1" 2>/dev/null | jq -r '
            .streams[] | select(.codec_type=="video") |
            "Resolution: \(.width)x\(.height)",
            "Codec: \(.codec_name)",
            "Bitrate: \(.bit_rate // "N/A") bps",
            "FPS: \(.r_frame_rate)"
          ' 2>/dev/null || echo "Install jq for JSON parsing"
        }
      '';
    })
    
    # Image Tools Collection
    (lib.mkIf cfg.imageTools.enable {
      environment.systemPackages = with pkgs; 
        errors.recovery.withDefault [] (
          # Image processing tools
          (lib.optionals cfg.imageTools.includeProcessing [
            imagemagick           # Image manipulation suite
            graphicsmagick        # GraphicsMagick image processing system
            gimp                  # GNU Image Manipulation Program
            inkscape              # Vector graphics editor
            optipng               # PNG optimizer
            jpegoptim             # JPEG optimizer
            pngcrush              # PNG optimizer
            webp                  # WebP image format tools
            libavif               # AVIF image format tools
          ]) ++
          
          # Text art and ASCII tools
          (lib.optionals cfg.imageTools.includeTextArt [
            figlet                # ASCII art text generator
            toilet                # Enhanced figlet
            boxes                 # Text mode box drawing
            cowsay                # Configurable speaking cow
            fortune               # Fortune cookie program
            lolcat                # Rainbow coloring
            cmatrix               # Matrix-style falling characters
            asciiquarium          # ASCII aquarium animation
            sl                    # Steam locomotive animation
          ]) ++
          
          # Terminal image viewers
          (lib.optionals cfg.imageTools.includeViewing [
            feh                   # Image viewer and wallpaper setter
            sxiv                  # Simple X Image Viewer
            fim                   # Framebuffer/ASCII art image viewer
            tiv                   # Terminal image viewer
            catimg                # Terminal image viewer
            chafa                 # Terminal graphics format
            viu                   # Terminal image viewer in Rust
          ]) ++
          
          # Image utilities
          [
            exiftool              # Image metadata tool
            jhead                 # JPEG header manipulation
            jpeginfo              # JPEG file information
            pnginfo               # PNG file information
            identify              # ImageMagick identify tool
            qrencode              # QR code generator
            zbar                  # QR/barcode reader
          ]
        );
        
      # Image tools aliases
      environment.shellAliases = {
        img-view = "feh";
        img-info = "identify";
        img-meta = "exiftool";
        ascii-art = "figlet";
        banner = "toilet";
        qr = "qrencode";
        qr-read = "zbarimg";
        img-optimize = "optipng";
        img-compress = "jpegoptim";
        img-convert = "convert";
        rainbow = "lolcat";
        matrix = "cmatrix";
        aquarium = "asciiquarium";
        train = "sl";
      };
      
      # Image processing functions
      environment.shellInit = ''
        # Image conversion
        img-convert() {
          if [ $# -lt 2 ]; then
            echo "Usage: img-convert <input> <output> [options]"
            return 1
          fi
          convert "$1" "$2" "''${@:3}"
        }
        
        # Image resize
        img-resize() {
          if [ $# -lt 3 ]; then
            echo "Usage: img-resize <input> <output> <size>"
            echo "Size examples: 800x600, 50%, 800x (keep aspect ratio)"
            return 1
          fi
          convert "$1" -resize "$3" "$2"
        }
        
        # Image optimization
        img-optimize() {
          if [ -z "$1" ]; then
            echo "Usage: img-optimize <image-file>"
            return 1
          fi
          local file="$1"
          local ext="''${file##*.}"
          case "$ext" in
            png|PNG)
              optipng "$file"
              ;;
            jpg|jpeg|JPG|JPEG)
              jpegoptim "$file"
              ;;
            *)
              echo "Unsupported format: $ext"
              return 1
              ;;
          esac
        }
        
        # Generate QR code
        qr-gen() {
          if [ -z "$1" ]; then
            echo "Usage: qr-gen <text> [output-file]"
            return 1
          fi
          local output="''${2:-qrcode.png}"
          qrencode -o "$output" "$1"
          echo "QR code saved to: $output"
        }
        
        # Image information
        img-analyze() {
          if [ -z "$1" ]; then
            echo "Usage: img-analyze <image-file>"
            return 1
          fi
          echo "=== Image Information ==="
          identify -verbose "$1" | head -20
          echo ""
          echo "=== Metadata ==="
          exiftool "$1" | head -10
        }
        
        # Batch image operations
        img-batch() {
          if [ $# -lt 2 ]; then
            echo "Usage: img-batch <operation> <pattern> [args...]"
            echo "Operations: resize, convert, optimize"
            return 1
          fi
          local operation="$1"
          local pattern="$2"
          shift 2
          
          for file in $pattern; do
            case "$operation" in
              resize)
                if [ -n "$1" ]; then
                  img-resize "$file" "''${file%.*}_resized.''${file##*.}" "$1"
                fi
                ;;
              optimize)
                img-optimize "$file"
                ;;
              convert)
                if [ -n "$1" ]; then
                  convert "$file" "''${file%.*}.$1"
                fi
                ;;
            esac
          done
        }
      '';
    })
    
    # Document Tools Collection
    (lib.mkIf cfg.documentTools.enable {
      environment.systemPackages = with pkgs; 
        errors.recovery.withDefault [] (
          # Document conversion tools
          (lib.optionals cfg.documentTools.includeConversion [
            pandoc                # Universal document converter
            texlive.combined.scheme-medium  # LaTeX distribution
            libreoffice           # Office suite
            wkhtmltopdf           # HTML to PDF converter
            ghostscript           # PostScript and PDF interpreter
            poppler_utils         # PDF utilities
            qpdf                  # PDF manipulation
            pdftk                 # PDF toolkit
            pdfgrep               # Search PDF files
            mupdf                 # Lightweight PDF viewer/tools
          ]) ++
          
          # Document formatting tools
          (lib.optionals cfg.documentTools.includeFormatting [
            groff                 # GNU troff text formatting system
            asciidoc              # Text-based document generation
            asciidoctor           # Modern AsciiDoc processor
            markdown              # Markdown processor
            multimarkdown         # Enhanced Markdown
            rst2pdf               # ReStructuredText to PDF
            sphinx                # Documentation generator
            hugo                  # Static site generator
          ]) ++
          
          # Document utilities
          [
            man-db                # Manual page system
            info                  # GNU info reader
            texinfo               # GNU documentation system
            dict                  # Dictionary client
            wordnet               # Lexical database
            aspell                # Spell checker
            hunspell              # Spell checker
            languagetool          # Style and grammar checker
          ]
        );
        
      # Document tools aliases
      environment.shellAliases = {
        md2pdf = "pandoc -o";
        doc-convert = "pandoc";
        pdf-info = "pdfinfo";
        pdf-search = "pdfgrep";
        spell = "aspell";
        grammar = "languagetool";
        word-count = "wc -w";
        pdf-merge = "pdftk";
        html2pdf = "wkhtmltopdf";
      };
      
      # Document processing functions
      environment.shellInit = ''
        # Convert documents
        doc-convert() {
          if [ $# -lt 3 ]; then
            echo "Usage: doc-convert <input> <output> <format>"
            echo "Formats: pdf, html, docx, epub, etc."
            return 1
          fi
          pandoc "$1" -o "$2"
        }
        
        # Markdown to PDF
        md-to-pdf() {
          if [ -z "$1" ]; then
            echo "Usage: md-to-pdf <markdown-file> [output-file]"
            return 1
          fi
          local input="$1"
          local output="''${2:-''${input%.*}.pdf}"
          pandoc "$input" -o "$output" --pdf-engine=xelatex
        }
        
        # PDF operations
        pdf-split() {
          if [ $# -lt 3 ]; then
            echo "Usage: pdf-split <input.pdf> <start-page> <end-page> [output.pdf]"
            return 1
          fi
          local input="$1"
          local start="$2"
          local end="$3"
          local output="''${4:-split_''${start}-''${end}.pdf}"
          pdftk "$input" cat "$start-$end" output "$output"
        }
        
        # PDF merge
        pdf-merge() {
          if [ $# -lt 3 ]; then
            echo "Usage: pdf-merge <output.pdf> <input1.pdf> <input2.pdf> [input3.pdf...]"
            return 1
          fi
          local output="$1"
          shift
          pdftk "$@" cat output "$output"
        }
        
        # Document statistics
        doc-stats() {
          if [ -z "$1" ]; then
            echo "Usage: doc-stats <document-file>"
            return 1
          fi
          echo "=== Document Statistics ==="
          echo "File: $1"
          echo "Size: $(du -h "$1" | cut -f1)"
          echo "Words: $(wc -w < "$1")"
          echo "Lines: $(wc -l < "$1")"
          echo "Characters: $(wc -c < "$1")"
          echo "Characters (no spaces): $(tr -d ' \t\n' < "$1" | wc -c)"
        }
      '';
    })
    
    # Presentation Tools (Optional)
    (lib.mkIf cfg.presentationTools.enable {
      environment.systemPackages = with pkgs; 
        errors.recovery.withDefault [] [
          sent                  # Simple terminal presentation tool
          mdp                   # Markdown presentations
          present               # Terminal slide presentations
          tpp                   # Text presentation program
          beamer2thesis         # LaTeX Beamer to thesis converter
        ];
        
      # Presentation aliases
      environment.shellAliases = {
        present = "mdp";
        slides = "sent";
        tty-present = "tpp";
      };
    })
    
    # Integration and Enhancement
    {
      # Multimedia environment variables
      environment.variables = {
        # Default media player
        MEDIA_PLAYER = lib.mkDefault "mpv";
        
        # Image viewer
        IMAGE_VIEWER = lib.mkDefault "feh";
        
        # Audio player
        AUDIO_PLAYER = lib.mkDefault "cmus";
      };
      
      # Enhanced multimedia functions
      environment.shellInit = ''
        # Universal media opener
        media-open() {
          if [ -z "$1" ]; then
            echo "Usage: media-open <file-or-url>"
            return 1
          fi
          
          local file="$1"
          local mime=$(file --mime-type -b "$file" 2>/dev/null || echo "unknown")
          
          case "$mime" in
            audio/*)
              mpv --no-video "$file"
              ;;
            video/*)
              mpv "$file"
              ;;
            image/*)
              feh "$file"
              ;;
            application/pdf)
              mupdf "$file" &
              ;;
            *)
              echo "Unknown media type: $mime"
              echo "Trying default player..."
              mpv "$file"
              ;;
          esac
        }
        
        # Media information
        media-info() {
          if [ -z "$1" ]; then
            echo "Usage: media-info <media-file>"
            return 1
          fi
          
          echo "=== Media File Information ==="
          echo "File: $1"
          echo "Type: $(file "$1")"
          echo "Size: $(du -h "$1" | cut -f1)"
          echo ""
          mediainfo "$1" 2>/dev/null || ffprobe "$1" 2>&1 | grep -E "(Duration|Stream|Video|Audio)"
        }
        
        # Quick media conversion
        media-quick-convert() {
          if [ $# -lt 2 ]; then
            echo "Usage: media-quick-convert <input> <output-format>"
            echo "Formats: mp3, mp4, avi, webm, gif, png, jpg"
            return 1
          fi
          
          local input="$1"
          local format="$2"
          local output="''${input%.*}.$format"
          
          case "$format" in
            mp3)
              ffmpeg -i "$input" -acodec libmp3lame "$output"
              ;;
            mp4)
              ffmpeg -i "$input" -c:v libx264 -c:a aac "$output"
              ;;
            webm)
              ffmpeg -i "$input" -c:v libvpx-vp9 -c:a libopus "$output"
              ;;
            gif)
              ffmpeg -i "$input" -vf "fps=10,scale=480:-1:flags=lanczos" "$output"
              ;;
            png|jpg)
              convert "$input" "$output"
              ;;
            *)
              echo "Unsupported format: $format"
              return 1
              ;;
          esac
        }
      '';
      
      # Documentation
      documentation = {
        enable = true;
        man.enable = true;
        info.enable = true;
      };
    }
  ]);
}