import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class EnhancedTikTokPlayer extends StatefulWidget {
  final String videoUrl;
  final Function? onPlay;
  final Function? onPause;
  
  const EnhancedTikTokPlayer({
    Key? key,
    required this.videoUrl,
    this.onPlay,
    this.onPause,
  }) : super(key: key);

  @override
  _EnhancedTikTokPlayerState createState() => _EnhancedTikTokPlayerState();
}

class _EnhancedTikTokPlayerState extends State<EnhancedTikTokPlayer> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _isPlaying = true;
  bool _soundEnabled = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }
  
  void _initWebView() {
    // Create WebView controller with simplified configuration
    final WebViewController controller = WebViewController();
    
    // Configure WebView options
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            _injectCustomCSS();
            _enableSound();
            setState(() {
              _isLoading = false;
            });
          },
        ),
      );
    
    // Configure platform-specific settings if needed
    if (WebViewPlatform.instance != null) {
      // Set up platform-specific settings through JavaScript for maximum compatibility
      controller.runJavaScript('''
        // Try to enable autoplay through HTML5 video attributes
        document.addEventListener('DOMContentLoaded', function() {
          const videos = document.querySelectorAll('video');
          videos.forEach(v => {
            v.setAttribute('autoplay', '');
            v.setAttribute('playsinline', '');
            v.setAttribute('webkit-playsinline', '');
          });
        });
      ''');
    }
    
    // Load the TikTok URL
    controller.loadRequest(Uri.parse(widget.videoUrl));
    _controller = controller;
  }
  
  // Inject custom CSS to hide TikTok UI elements and show only the video
  Future<void> _injectCustomCSS() async {
    await _controller.runJavaScript('''
      var style = document.createElement('style');
      style.textContent = `
        /* Hide unnecessary elements */
        header, footer, .sidebar, .video-card-container, .comments, .video-controls, .share-container { 
          display: none !important; 
        }
        
        /* Make video fill the screen */
        .video-feed, .video-player, .video-container {
          width: 100% !important;
          height: 100% !important;
          position: fixed !important;
          top: 0 !important;
          left: 0 !important;
          margin: 0 !important;
          padding: 0 !important;
        }
        
        /* Make video content visible and centered */
        video {
          width: 100% !important;
          height: 100% !important;
          object-fit: contain !important;
          background: black !important;
        }
        
        /* Hide cookie banners */
        .cookie-banner, .consent-banner, [class*="cookie"], [class*="consent"], [class*="gdpr"] {
          display: none !important;
        }
      `;
      document.head.appendChild(style);
      
      // Auto-click any visible cookie accept buttons
      setTimeout(function() {
        const acceptButtons = document.querySelectorAll('button, a, [role="button"]');
        for (const button of acceptButtons) {
          if (button.innerText && (
              button.innerText.includes('Accept') || 
              button.innerText.includes('Allow') || 
              button.innerText.includes('Agree') ||
              button.innerText.includes('Allow all'))) {
            button.click();
            console.log('Auto-clicked accept button');
          }
        }
      }, 1000);
    ''');
  }
  
  // Enable sound by finding and unmuting all video elements
  Future<void> _enableSound() async {
    await _controller.runJavaScript('''
      // Function to enable sound on all videos
      function enableSound() {
        const videos = document.querySelectorAll('video');
        videos.forEach(video => {
          // Unmute the video
          video.muted = false;
          // Set volume to max
          video.volume = 1.0;
          
          // Force play with sound if paused
          if (video.paused) {
            video.play()
              .then(() => console.log('Video playing with sound'))
              .catch(e => console.error('Error playing video:', e));
          }
          
          console.log('Sound enabled for video');
        });
      }
      
      // Run immediately
      enableSound();
      
      // Also run when user interacts with the page
      document.addEventListener('click', function() {
        enableSound();
      });
      
      // And run periodically to catch newly loaded videos
      setInterval(enableSound, 2000);
      
      // Auto-accept any permissions dialogs
      setTimeout(function() {
        const permissionButtons = document.querySelectorAll('[aria-label*="Allow"], [aria-label*="Accept"]');
        for (const button of permissionButtons) {
          button.click();
          console.log('Auto-clicked permission button');
        }
      }, 1500);
    ''');
  }
  
  void _togglePlayPause() {
    _controller.runJavaScript('''
      const videos = document.querySelectorAll('video');
      videos.forEach(video => {
        if (video.paused) {
          video.play();
          video.muted = false;
          video.volume = 1.0;
        } else {
          video.pause();
        }
      });
    ''');
    
    setState(() {
      _isPlaying = !_isPlaying;
    });
    
    if (_isPlaying) {
      if (widget.onPlay != null) widget.onPlay!();
    } else {
      if (widget.onPause != null) widget.onPause!();
    }
    
    // Also try to re-enable sound when user interacts
    _enableSound();
  }

  // Toggle sound manually
  void _toggleSound() {
    setState(() {
      _soundEnabled = !_soundEnabled;
    });
    
    _controller.runJavaScript('''
      const videos = document.querySelectorAll('video');
      videos.forEach(video => {
        video.muted = ${!_soundEnabled};
        video.volume = 1.0;
        console.log('Sound ${_soundEnabled ? 'enabled' : 'disabled'}');
      });
    ''');
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          // WebView with explicit size constraints
          Container(
            color: Colors.black,
            child: WebViewWidget(controller: _controller),
          ),
          
          // Loading indicator
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          
          // Custom play/pause button overlay
          if (!_isLoading)
            GestureDetector(
              onTap: _togglePlayPause,
              child: Container(
                color: Colors.transparent,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _isPlaying ? 0.0 : 0.7,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
          // Sound toggle button
          Positioned(
            bottom: 10,
            right: 10,
            child: GestureDetector(
              onTap: _toggleSound,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _soundEnabled ? Icons.volume_up : Icons.volume_off,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}