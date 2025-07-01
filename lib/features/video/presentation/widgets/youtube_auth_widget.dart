import 'package:flutter/material.dart';
import '../../../../services/auth/youtube_oauth_service.dart';

/// Widget to handle YouTube OAuth authentication for subtitle access
class YouTubeAuthWidget extends StatefulWidget {
  final VoidCallback? onAuthSuccess;
  final VoidCallback? onAuthFailed;

  const YouTubeAuthWidget({
    super.key,
    this.onAuthSuccess,
    this.onAuthFailed,
  });

  @override
  State<YouTubeAuthWidget> createState() => _YouTubeAuthWidgetState();
}

class _YouTubeAuthWidgetState extends State<YouTubeAuthWidget> {
  final YouTubeOAuthService _oauthService = YouTubeOAuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.closed_caption,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'YouTube Subtitle Access',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_oauthService.isAuthenticated) ...[
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Authenticated for YouTube subtitle access',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _signOut,
                      child: const Text('Sign Out'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'Some YouTube videos have subtitles that require authentication to access. Sign in with your Google account to download these subtitles.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _signIn,
                      icon: _isLoading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : const Icon(Icons.login),
                      label: Text(_isLoading ? 'Signing In...' : 'Sign In with Google'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Note: This requires YouTube API access permissions.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _oauthService.signIn();
      
      if (success) {
        widget.onAuthSuccess?.call();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully signed in for YouTube subtitle access'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        widget.onAuthFailed?.call();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to sign in. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      widget.onAuthFailed?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _oauthService.signOut();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed out successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign out error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}