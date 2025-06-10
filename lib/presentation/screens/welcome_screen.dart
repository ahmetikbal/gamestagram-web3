import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../widgets/animated_game_background.dart';
import 'registration_screen.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Animated game icons background
          AnimatedGameBackground(
            gameIcons: const [], // Will use default sample icons
            opacity: 0.15,
          ),
          
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withOpacity(0.4),
                  theme.colorScheme.secondary.withOpacity(0.6),
                  theme.colorScheme.tertiary?.withOpacity(0.3) ?? Colors.purple.withOpacity(0.3),
                  theme.scaffoldBackgroundColor.withOpacity(0.8),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
          
          // Content
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo and title section with glassmorphism
                    Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.white.withOpacity(0.1),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Column(
                            children: [
                              // App icon
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      theme.colorScheme.primary,
                                      theme.colorScheme.secondary,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.videogame_asset_rounded,
                                  size: 50,
                                  color: Colors.white,
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // App title
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.secondary,
                                    theme.colorScheme.tertiary ?? Colors.purple,
                                  ],
                                ).createShader(bounds),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Gamestagram',
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.visible,
                                    style: GoogleFonts.poppins(
                                      fontSize: 42,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Subtitle
                              Text(
                                'Swipe, Play, Connect.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.9),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // Buttons section
                    Column(
                      children: [
                        // Register button
                        _buildGlassmorphismButton(
                          context: context,
                          text: 'Get Started',
                          icon: Icons.rocket_launch_rounded,
                          isPrimary: true,
                                                     onPressed: () {
                             Navigator.push(
                               context,
                               MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                             );
                           },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Login button
                        _buildGlassmorphismButton(
                          context: context,
                          text: 'Sign In',
                          icon: Icons.login_rounded,
                          isPrimary: false,
                                                     onPressed: () {
                             Navigator.push(
                               context,
                               MaterialPageRoute(builder: (context) => const LoginScreen()),
                             );
                           },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Features section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white.withOpacity(0.05),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildFeatureItem(
                            icon: Icons.games_rounded,
                            label: '3965+\nGames',
                            color: theme.colorScheme.primary,
                          ),
                          _buildFeatureItem(
                            icon: Icons.favorite_rounded,
                            label: 'Social\nFeatures',
                            color: theme.colorScheme.secondary,
                          ),
                          _buildFeatureItem(
                            icon: Icons.all_inclusive,
                            label: 'Infinite\nScroll',
                            color: theme.colorScheme.tertiary ?? Colors.purple,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassmorphismButton({
    required BuildContext context,
    required String text,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: isPrimary
            ? LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isPrimary ? null : Colors.white.withOpacity(0.1),
        border: Border.all(
          color: Colors.white.withOpacity(isPrimary ? 0.3 : 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isPrimary ? theme.colorScheme.primary : Colors.black)
                .withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(20),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      text,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.2),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.8),
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
 