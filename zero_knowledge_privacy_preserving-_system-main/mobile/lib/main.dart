import 'package:flutter/material.dart';
import 'core/vault_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/activity_screen.dart';
import 'screens/proof_home_screen.dart';
import 'screens/wallet_home_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ZkMatchIdApp());
}

class ZkMatchIdApp extends StatelessWidget {
  const ZkMatchIdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'zk-MatchID',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const WalletLaunchScreen(),
    );
  }
}

class WalletLaunchScreen extends StatefulWidget {
  const WalletLaunchScreen({super.key});

  @override
  State<WalletLaunchScreen> createState() => _WalletLaunchScreenState();
}

class _WalletLaunchScreenState extends State<WalletLaunchScreen> {
  final VaultService _vault = VaultService();
  late Future<_WalletLaunchState> _launchState;

  @override
  void initState() {
    super.initState();
    _launchState = _loadLaunchState();
  }

  Future<_WalletLaunchState> _loadLaunchState() async {
    try {
      final onboarded = await _vault.isOnboardingComplete();
      if (!onboarded) return const _WalletLaunchState.needsOnboarding();
      return const _WalletLaunchState(onboardingComplete: true);
    } catch (_) {
      return const _WalletLaunchState.needsOnboarding();
    }
  }

  void _openWallet() => setState(
    () => _launchState = Future<_WalletLaunchState>.value(
      const _WalletLaunchState(onboardingComplete: true),
    ),
  );

  void _restartWalletSetup() => setState(
    () => _launchState = Future<_WalletLaunchState>.value(
      const _WalletLaunchState.needsOnboarding(),
    ),
  );

  @override
  Widget build(BuildContext context) => FutureBuilder<_WalletLaunchState>(
    future: _launchState,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return OnboardingScreen(onComplete: _openWallet);
      }
      final launchState =
          snapshot.data ?? const _WalletLaunchState.needsOnboarding();
      if (!launchState.onboardingComplete) {
        return OnboardingScreen(onComplete: _openWallet);
      }
      return MainNavigationScreen(onWalletWiped: _restartWalletSetup);
    },
  );
}

class _WalletLaunchState {
  const _WalletLaunchState({required this.onboardingComplete});

  const _WalletLaunchState.needsOnboarding() : onboardingComplete = false;

  final bool onboardingComplete;
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key, this.onWalletWiped});

  final VoidCallback? onWalletWiped;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const WalletHomeScreen(),
      const ProofHomeScreen(),
      const ActivityScreen(),
      SettingsScreen(onWalletWiped: widget.onWalletWiped),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_2_outlined),
            selectedIcon: Icon(Icons.qr_code_2),
            label: 'Prove',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
