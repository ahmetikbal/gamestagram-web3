# Gamestagram Web3 - Blockchain Gaming Marketplace

A revolutionary mobile gaming marketplace built on the Stellar blockchain, featuring Passkey authentication, play-to-earn mechanics, and decentralized gaming experiences.

## 🌟 Features

### 🔐 Web3 Authentication
- **Passkey Support**: Secure biometric authentication using WebAuthn
- **Stellar Wallet Integration**: Built-in cryptocurrency wallet for each user
- **Decentralized Identity**: Self-sovereign identity management

### 🎮 Gaming Features
- **TikTok-style Interface**: Swipe through games with smooth animations
- **Play-to-Earn**: Earn XLM and GAME tokens while playing
- **Smart Contract Integration**: Automated rewards and payments via Soroban
- **NFT Support**: Collect and trade in-game NFTs

### 💰 Blockchain Features
- **Stellar Network**: Fast, low-cost transactions
- **Launchtube Integration**: Fee sponsorship for seamless UX
- **Soroban Smart Contracts**: Automated game logic and rewards
- **Multi-token Support**: XLM, GAME tokens, and custom game tokens

### 🏗️ Developer Features
- **Revenue Sharing**: Transparent and instant payments
- **Analytics Dashboard**: Real-time game performance metrics
- **Staking Pools**: Earn passive income from game performance

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.7.2 or higher
- Dart SDK 2.14.0 or higher
- Android Studio / Xcode for mobile development
- Stellar Testnet account for development

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/gamestagram-web3.git
   cd gamestagram-web3
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate model files**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Configure Web3 services**
   - Update Stellar network configuration in `lib/services/stellar_service.dart`
   - Configure Soroban smart contract addresses
   - Set up Launchtube integration

5. **Run the application**
   ```bash
   flutter run
   ```

## 🏗️ Architecture

### Core Components

```
lib/
├── application/
│   └── view_models/
│       ├── web3_auth_view_model.dart      # Web3 authentication state
│       └── web3_game_view_model.dart      # Game interactions state
├── data/
│   └── models/
│       ├── user_model.dart                # User with Web3 features
│       └── game_model.dart                # Game with blockchain metadata
├── services/
│   ├── stellar_service.dart               # Stellar blockchain operations
│   ├── soroban_service.dart               # Smart contract interactions
│   ├── passkey_service.dart               # WebAuthn authentication
│   ├── launchtube_service.dart            # Fee sponsorship
│   ├── web3_auth_service.dart             # Combined Web3 auth
│   └── web3_game_service.dart             # Web3 game operations
└── presentation/
    └── screens/
        ├── web3_welcome_screen.dart        # Web3 onboarding
        ├── web3_login_screen.dart          # Passkey login
        └── web3_registration_screen.dart   # Web3 account creation
```

### Technology Stack

- **Frontend**: Flutter 3.7.2
- **Blockchain**: Stellar Network
- **Smart Contracts**: Soroban (Rust)
- **Authentication**: WebAuthn / Passkeys
- **Fee Sponsorship**: Launchtube
- **State Management**: Provider + ChangeNotifier
- **Dependency Injection**: GetIt

## 🔧 Configuration

### Stellar Network Setup

1. **Testnet Configuration** (Default)
   ```dart
   static const String _networkUrl = 'https://horizon-testnet.stellar.org';
   static const String _networkPassphrase = 'Test SDF Network ; September 2015';
   ```

2. **Mainnet Configuration** (Production)
   ```dart
   static const String _networkUrl = 'https://horizon.stellar.org';
   static const String _networkPassphrase = 'Public Global Stellar Network ; September 2015';
   ```

### Smart Contract Deployment

1. **Deploy Game Rewards Contract**
   ```bash
   # Compile Soroban contract
   soroban contract build
   
   # Deploy to testnet
   soroban contract deploy --network testnet --source admin target/wasm32-unknown-unknown/release/game_rewards.wasm
   ```

2. **Deploy Developer Payments Contract**
   ```bash
   soroban contract deploy --network testnet --source admin target/wasm32-unknown-unknown/release/developer_payments.wasm
   ```

### Launchtube Integration

Configure fee sponsorship in `lib/services/launchtube_service.dart`:

```dart
static const String _launchtubeUrl = 'https://launchtube.stellar.org';
static const String _testnetUrl = 'https://launchtube-testnet.stellar.org';
```

## 🎮 Usage

### For Players

1. **Create Web3 Account**
   - Download the app
   - Register with username and email
   - Complete Passkey setup
   - Receive Stellar wallet and recovery phrase

2. **Start Gaming**
   - Swipe through available games
   - Play games to earn XLM and GAME tokens
   - Complete achievements for bonus rewards
   - Trade NFTs in the marketplace

3. **Manage Wallet**
   - View balances and transaction history
   - Stake tokens in developer pools
   - Withdraw earnings to external wallets

### For Developers

1. **Publish Games**
   - Upload HTML5 games
   - Configure smart contract parameters
   - Set pricing and reward structures

2. **Monitor Performance**
   - Track player engagement metrics
   - View revenue analytics
   - Manage staking pools

3. **Earn Revenue**
   - Receive instant payments via smart contracts
   - Earn from staking pools
   - Collect platform fees

## 🔒 Security Features

- **Passkey Authentication**: Biometric security with WebAuthn
- **Secure Key Storage**: Encrypted storage using Flutter Secure Storage
- **Smart Contract Audits**: All contracts audited for security
- **Transaction Signing**: Secure transaction signing with hardware wallets
- **Fee Sponsorship**: Launchtube integration prevents fee-related attacks

## 🌐 Network Information

### Stellar Testnet
- **Network URL**: https://horizon-testnet.stellar.org
- **Network Passphrase**: Test SDF Network ; September 2015
- **Faucet**: https://laboratory.stellar.org/#account-creator

### Soroban Testnet
- **RPC URL**: https://soroban-testnet.stellar.org
- **Network Passphrase**: Test SDF Network ; September 2015

## 📱 Platform Support

- **iOS**: 12.0+
- **Android**: API Level 21+
- **Web**: Chrome 67+, Firefox 60+, Safari 13+

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow Flutter best practices
- Write comprehensive tests
- Update documentation for new features
- Ensure Web3 security best practices
- Test on both testnet and mainnet

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Stellar Development Foundation** for the blockchain infrastructure
- **Soroban Team** for smart contract platform
- **Launchtube** for fee sponsorship service
- **WebAuthn Community** for authentication standards

## 📞 Support

- **Documentation**: [Wiki](https://github.com/your-username/gamestagram-web3/wiki)
- **Issues**: [GitHub Issues](https://github.com/your-username/gamestagram-web3/issues)
- **Discord**: [Community Server](https://discord.gg/gamestagram-web3)
- **Email**: support@gamestagram-web3.com

## 🔮 Roadmap

### Phase 1: MVP (Current)
- ✅ Web3 authentication with Passkeys
- ✅ Stellar wallet integration
- ✅ Basic game marketplace
- ✅ Play-to-earn mechanics

### Phase 2: Enhanced Features
- 🔄 Advanced smart contracts
- 🔄 NFT marketplace
- 🔄 Developer analytics dashboard
- 🔄 Cross-chain integration

### Phase 3: Ecosystem Expansion
- 📋 Multi-chain support
- 📋 Advanced staking mechanisms
- 📋 DAO governance
- 📋 Mobile SDK for developers

---

**Built with ❤️ on the Stellar Network**
